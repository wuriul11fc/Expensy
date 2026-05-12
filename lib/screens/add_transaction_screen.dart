// lib/screens/add_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipt_recognition/receipt_recognition.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? existing;
  const AddTransactionScreen({super.key, this.existing});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _type = 'expense';
  String? _accountId;
  String? _categoryId;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _amountCtrl.text = e.amount.toString();
      _descCtrl.text = e.description;
      _noteCtrl.text = e.note;
      _type = e.type;
      _accountId = e.accountId;
      _categoryId = e.categoryId;
      _date = e.date;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_amountCtrl.text.isEmpty || _accountId == null || _categoryId == null) return;
    final app = Provider.of<AppProvider>(context, listen: false);
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    final tx = Transaction(
      id: widget.existing?.id ?? app.newId(),
      accountId: _accountId!,
      categoryId: _categoryId!,
      amount: amount,
      type: _type,
      description: _descCtrl.text.trim(),
      date: _date,
      note: _noteCtrl.text.trim(),
    );
    if (widget.existing != null) {
      await app.updateTransaction(widget.existing!, tx);
    } else {
      await app.addTransaction(tx);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final cs = Theme.of(context).colorScheme;
    final sym = currencyInfo(app.settings.currency).symbol;
    final headerColor = cs.primary;

    final filteredCats = app.categories.where((c) => c.type == _type).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add Transaction' : 'Edit Transaction', style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: headerColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Expense'), icon: Icon(Icons.arrow_upward_rounded)),
                ButtonSegment(value: 'income', label: Text('Income'), icon: Icon(Icons.arrow_downward_rounded)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() { _type = s.first; _categoryId = null; }),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(children: [
                Text('Amount', style: TextStyle(fontSize: 12, color: cs.onSurface.withAlpha(150))),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(sym, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: headerColor)),
                    SizedBox(
                      width: 180,
                      child: TextField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: headerColor),
                        decoration: const InputDecoration(border: InputBorder.none, hintText: '0.00'),
                      ),
                    ),
                  ],
                ),
              ]),
            ),
            const SizedBox(height: 16),
            TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.notes_outlined))),
            const SizedBox(height: 14),
            if (app.accounts.isNotEmpty) ...[
              Text('Account', style: Theme.of(context).textTheme.labelMedium?.copyWith(letterSpacing: 1)),
              const SizedBox(height: 8),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: app.accounts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final acc = app.accounts[i];
                    final sel = _accountId == acc.id;
                    return GestureDetector(
                      onTap: () => setState(() => _accountId = acc.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 130,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? Color(acc.colorValue) : Color(acc.colorValue).withAlpha(25),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: sel ? Color(acc.colorValue) : Color(acc.colorValue).withAlpha(90), width: sel ? 2 : 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AccountTypeIcon(type: acc.type, size: 16, color: sel ? Colors.white : Color(acc.colorValue)),
                            const SizedBox(height: 4),
                            Text(acc.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sel ? Colors.white : Color(acc.colorValue))),
                            Text(formatAmount(acc.balance, acc.currency), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: sel ? Colors.white.withAlpha(200) : cs.onSurface.withAlpha(130))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (filteredCats.isNotEmpty) ...[
              Text('Category', style: Theme.of(context).textTheme.labelMedium?.copyWith(letterSpacing: 1)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: filteredCats.map((c) {
                  final sel = _categoryId == c.id;
                  return GestureDetector(
                    onTap: () => setState(() => _categoryId = c.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 80),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? Color(c.colorValue) : Color(c.colorValue).withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: sel ? Colors.white : Color(c.colorValue), shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(c.name, style: TextStyle(color: sel ? Colors.white : Color(c.colorValue), fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text('${_date.day}/${_date.month}/${_date.year}', style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: const Text('Tap to change date'),
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 1)));
                if (picked != null) setState(() => _date = picked);
              },
            ),
            TextField(controller: _noteCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Note (optional)', prefixIcon: Icon(Icons.sticky_note_2_outlined))),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _submit,
              icon: Icon(widget.existing == null ? Icons.check_rounded : Icons.save_outlined),
              label: Text(widget.existing == null ? 'Add $_type' : 'Save Changes'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: headerColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            final receipt = await ReceiptRecognizer().processImageFromCamera();
            if (receipt != null && mounted) {
              _amountCtrl.text = receipt.totalAmount?.toString() ?? '';
              if (receipt.date != null) _date = receipt.date!;
              if (receipt.merchantName != null && _descCtrl.text.isEmpty) {
                _descCtrl.text = receipt.merchantName!;
              }
            }
          } catch (e) {
            // ignore – user can type manually
          }
        },
        child: const Icon(Icons.receipt),
      ),
    );
  }
}
