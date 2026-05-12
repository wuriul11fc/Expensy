// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../database/db_helper.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _uuid = const Uuid();
  int _step = 0;
  final _nameCtrl = TextEditingController();
  String _currency = 'EGP';
  final List<Account> _accounts = [];
  final _accNameCtrl = TextEditingController();
  String _accType = 'bank';
  final _accBalCtrl = TextEditingController(text: '0');
  int _accColor = 0xFF6750A4;

  static const List<int> _colors = [
    0xFF6750A4, 0xFF7D5260, 0xFF1565C0,
    0xFF2E7D32, 0xFFE65100, 0xFF00897B,
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _accNameCtrl.dispose();
    _accBalCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final app = Provider.of<AppProvider>(context, listen: false);
    final name = _nameCtrl.text.trim().isEmpty ? 'Friend' : _nameCtrl.text.trim();

    final accountsToInsert = _accounts.isEmpty
        ? [
            Account(
              id: _uuid.v4(),
              name: 'Main Account',
              type: 'bank',
              balance: 0,
              currency: _currency,
              colorValue: 0xFF6750A4,
            )
          ]
        : List.from(_accounts);

    for (final a in accountsToInsert) {
      await DBHelper.insertAccount(a);
    }

    await app.completeOnboarding(name: name, currency: _currency);
  }

  void _addAccount() {
    final name = _accNameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _accounts.add(Account(
        id: _uuid.v4(),
        name: name,
        type: _accType,
        balance: double.tryParse(_accBalCtrl.text) ?? 0,
        currency: _currency,
        colorValue: _accColor,
      ));
      _accNameCtrl.clear();
      _accBalCtrl.text = '0';
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: List.generate(4, (i) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i <= _step ? cs.primary : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: [
                    _buildWelcome(cs),
                    _buildName(cs),
                    _buildCurrency(cs),
                    _buildAccounts(cs),
                  ][_step],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome(ColorScheme cs) {
    return Column(
      key: const ValueKey(0),
      children: [
        const SizedBox(height: 40),
        Image.asset(
          'assets/splash_icon.png',
          width: 120,
          height: 120,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 32),
        Text(
          'Welcome to Expensy',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Your privacy-first expense manager\nNo internet permission needed',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withAlpha(150),
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        FilledButton(
          onPressed: () => setState(() => _step = 1),
          child: const Text('Get Started'),
        ),
      ],
    );
  }

  Widget _buildName(ColorScheme cs) {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'What should we call you?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Your name',
            prefixIcon: Icon(Icons.person_outline),
          ),
          autofocus: true,
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => setState(() => _step = 2),
          child: const Text('Next'),
        ),
      ],
    );
  }

  Widget _buildCurrency(ColorScheme cs) {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Choose your currency',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _currency,
          decoration: const InputDecoration(
            labelText: 'Currency',
            prefixIcon: Icon(Icons.monetization_on_outlined),
          ),
          items: kCurrencies.map((cur) {
            return DropdownMenuItem<String>(
              value: cur.code,
              child: Text('${cur.code}  ${cur.symbol}  — ${cur.name}'),
            );
          }).toList(),
          onChanged: (v) => setState(() => _currency = v!),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => setState(() => _step = 3),
          child: const Text('Next'),
        ),
      ],
    );
  }

  Widget _buildAccounts(ColorScheme cs) {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Add your accounts',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'You can add more later',
          style: TextStyle(
            color: cs.onSurface.withAlpha(150),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 20),
        if (_accounts.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _accounts.length,
              separatorBuilder: (_, __) => Divider(
                height: 0,
                color: cs.outlineVariant,
              ),
              itemBuilder: (_, i) {
                final a = _accounts[i];
                return ListTile(
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(a.colorValue).withAlpha(38),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: AccountTypeIcon(type: a.type, size: 16),
                    ),
                  ),
                  title: Text(a.name),
                  subtitle: Text(formatAmount(a.balance, a.currency)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () {
                      setState(() {
                        _accounts.removeAt(i);
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: cs.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _accNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Account name',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _accType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'bank', child: Text('Bank Account')),
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'savings', child: Text('Savings')),
                    DropdownMenuItem(value: 'credit', child: Text('Credit Card')),
                    DropdownMenuItem(value: 'wallet', child: Text('E-Wallet')),
                  ],
                  onChanged: (v) => setState(() => _accType = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _accBalCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Balance',
                    isDense: true,
                    prefixText: '${currencyInfo(_currency).symbol} ',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  children: _colors.map((col) {
                    return GestureDetector(
                      onTap: () => setState(() => _accColor = col),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(col),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _accColor == col ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _addAccount,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Account'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _step > 0 ? () => setState(() => _step--) : null,
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _finish,
                child: const Text('Finish'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
