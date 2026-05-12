// lib/screens/recurring_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class RecurringScreen extends StatelessWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final cs = Theme.of(context).colorScheme;
    final currency = app.settings.currency;
    String fmt(double v) => formatAmount(v, currency);

    double estMonthly = 0;
    for (final r in app.recurring) {
      switch (r.freqUnit) {
        case 'days':
          estMonthly += r.amount * (30.44 / r.freqVal);
          break;
        case 'weeks':
          estMonthly += r.amount * (4.33 / r.freqVal);
          break;
        case 'months':
          estMonthly += r.amount / r.freqVal;
          break;
        case 'years':
          estMonthly += r.amount / (12 * r.freqVal);
          break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Payments', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monthly', style: TextStyle(fontSize: 11, color: cs.onPrimaryContainer.withAlpha(165), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(fmt(estMonthly), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cs.primary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Weekly', style: TextStyle(fontSize: 11, color: cs.onSecondaryContainer.withAlpha(165), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(fmt(estMonthly / 4.33), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cs.secondary)),
                    ],
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: app.recurring.isEmpty
                ? const EmptyState(
                    icon: Icons.repeat_rounded,
                    message: 'No recurring payments',
                    subMessage: 'Track subscriptions & instalments',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
                    itemCount: app.recurring.length,
                    itemBuilder: (_, i) => _RecurringCard(r: app.recurring[i], app: app, fmt: fmt),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSheet(context, app),
        child: const Icon(Icons.add),
      ),
    );
  }

  static void _showSheet(BuildContext ctx, AppProvider app, {RecurringPayment? existing}) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _RecurringSheet(app: app, existing: existing),
    );
  }
}

class _RecurringCard extends StatelessWidget {
  final RecurringPayment r;
  final AppProvider app;
  final String Function(double) fmt;
  const _RecurringCard({required this.r, required this.app, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currency = app.settings.currency;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.repeat_rounded, color: cs.primary, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(r.frequencyLabel, style: TextStyle(fontSize: 12, color: cs.onSurface.withAlpha(150))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatAmount(r.amount, currency),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cs.primary),
                    ),
                    const SizedBox(height: 2),
                    if (r.endDate != null)
                      Text('${r.remainingPayments ?? 0} left', style: TextStyle(fontSize: 10, color: cs.onSurface.withAlpha(130))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => RecurringScreen._showSheet(context, app, existing: r),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      final ok = await showDeleteConfirm(context, r.name);
                      if (ok && context.mounted) app.deleteRecurring(r.id);
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.error,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurringSheet extends StatefulWidget {
  final AppProvider app;
  final RecurringPayment? existing;
  const _RecurringSheet({required this.app, this.existing});

  @override
  State<_RecurringSheet> createState() => _RecurringSheetState();
}

class _RecurringSheetState extends State<_RecurringSheet> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String? _accountId;
  String? _categoryId;
  int _freqVal = 1;
  String _freqUnit = 'months';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  String _notes = '';

  List<Account> get _accounts => widget.app.accounts;
  List<Category> get _categories => widget.app.categories.where((c) => c.type == 'expense').toList();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _amountCtrl.text = e.amount.toString();
      _accountId = e.accountId;
      _categoryId = e.categoryId;
      _freqVal = e.freqVal;
      _freqUnit = e.freqUnit;
      _startDate = e.startDate;
      _endDate = e.endDate;
      _notes = e.notes;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _amountCtrl.text.isEmpty || _accountId == null || _categoryId == null) return;
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    final app = widget.app;
    final now = DateTime.now();
    final nextDate = _startDate.isAfter(now) ? _startDate : _startDate;

    if (widget.existing != null) {
      final updated = RecurringPayment(
        id: widget.existing!.id,
        name: _nameCtrl.text.trim(),
        accountId: _accountId!,
        categoryId: _categoryId!,
        amount: amount,
        freqVal: _freqVal,
        freqUnit: _freqUnit,
        startDate: _startDate,
        nextDate: nextDate,
        endDate: _endDate,
        paidPayments: widget.existing!.paidPayments,
        reminderEnabled: true,
        notes: _notes,
      );
      await app.updateRecurring(updated);
    } else {
      final newRecurring = RecurringPayment(
        id: app.newId(),
        name: _nameCtrl.text.trim(),
        accountId: _accountId!,
        categoryId: _categoryId!,
        amount: amount,
        freqVal: _freqVal,
        freqUnit: _freqUnit,
        startDate: _startDate,
        nextDate: nextDate,
        endDate: _endDate,
        paidPayments: 0,
        reminderEnabled: true,
        notes: _notes,
      );
      await app.addRecurring(newRecurring);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? 'Edit Recurring Payment' : 'Add Recurring Payment', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name (e.g., Netflix, Rent)', prefixIcon: Icon(Icons.label_outline)), autofocus: true),
            const SizedBox(height: 14),
            TextField(controller: _amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount', prefixIcon: Icon(Icons.attach_money))),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _accountId,
              decoration: const InputDecoration(labelText: 'Account', prefixIcon: Icon(Icons.account_balance_wallet_outlined)),
              items: _accounts.map((acc) => DropdownMenuItem(value: acc.id, child: Text(acc.name))).toList(),
              onChanged: (v) => setState(() => _accountId = v),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _categoryId,
              decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined)),
              items: _categories.map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name))).toList(),
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _freqVal.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Every', isDense: true),
                    onChanged: (v) => setState(() => _freqVal = int.tryParse(v) ?? 1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _freqUnit,
                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                    items: const [
                      DropdownMenuItem(value: 'days', child: Text('Days')),
                      DropdownMenuItem(value: 'weeks', child: Text('Weeks')),
                      DropdownMenuItem(value: 'months', child: Text('Months')),
                      DropdownMenuItem(value: 'years', child: Text('Years')),
                    ],
                    onChanged: (v) => setState(() => _freqUnit = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text('Start: ${DateFormat('dd MMM yyyy').format(_startDate)}'),
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365 * 5)));
                if (picked != null) setState(() => _startDate = picked);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_view_day_outlined),
              title: Text(_endDate == null ? 'End: Never' : 'End: ${DateFormat('dd MMM yyyy').format(_endDate!)}'),
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: _endDate ?? _startDate.add(const Duration(days: 365)), firstDate: _startDate, lastDate: _startDate.add(const Duration(days: 365 * 10)));
                setState(() => _endDate = picked);
              },
            ),
            if (_endDate != null)
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => setState(() => _endDate = null), child: const Text('Remove end date'))]),
            const SizedBox(height: 14),
            TextField(
              controller: TextEditingController(text: _notes),
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes (optional)', prefixIcon: Icon(Icons.sticky_note_2_outlined)),
              onChanged: (v) => _notes = v,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
              child: Text(isEdit ? 'Save Changes' : 'Add Payment'),
            ),
          ],
        ),
      ),
    );
  }
}
