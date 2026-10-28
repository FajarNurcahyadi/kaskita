import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/tx_widgets.dart';

const _border = Color(0xFFC8DBD7);

/// Tab 1 - Tambah Transaksi (pengeluaran / pemasukan).
class AddTransactionScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSaved;
  const AddTransactionScreen({super.key, required this.onBack, required this.onSaved});
  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  bool _isExpense = true;
  String? _category;
  DateTime _date = today();
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final digits = _amount.text.replaceAll('.', '');
    final amount = int.tryParse(digits) ?? 0;
    if (amount <= 0) return showError(context, 'Masukkan jumlah lebih dari 0');
    if (_isExpense && _category == null) return showError(context, 'Pilih kategori pengeluaran');

    setState(() => _saving = true);
    try {
      await Api.addTransaction(
        type: _isExpense ? 'expense' : 'income',
        amount: amount,
        category: _isExpense ? _category! : 'pemasukan',
        date: isoDate(_date),
        note: _note.text.trim(),
      );
      if (!mounted) return;
      showInfo(context, 'Transaksi tersimpan');
      widget.onSaved();
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final isMobile = MediaQuery.sizeOf(context).width < 700;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(17, top + (isMobile ? 24 : 40), 17, 24),
        children: [
          Row(children: [
            GestureDetector(
                onTap: widget.onBack, child: const Icon(Icons.arrow_back, size: 24, color: AppColors.primary)),
            const SizedBox(width: 8),
            Text('Tambah Transaksi', style: inter(24, weight: FontWeight.w600, color: const Color(0xFF006363))),
          ]),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.fromLTRB(21, 34, 21, 24),
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _toggle(),
              const SizedBox(height: 22),
              Text('Jumlah', style: inter(12)),
              const SizedBox(height: 2),
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Text('Rp', style: inter(24, weight: FontWeight.w700)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsFormatter()],
                    style: inter(24, weight: FontWeight.w700),
                    cursorColor: AppColors.primary,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: inter(24, weight: FontWeight.w700, color: const Color(0xFFAAAAAA)),
                    ),
                  ),
                ),
              ]),
              Container(height: 1, color: Colors.black),
              if (_isExpense) ...[
                const SizedBox(height: 22),
                Text('Category', style: inter(12)),
                const SizedBox(height: 14),
                _categories(),
              ],
              const SizedBox(height: 22),
              Text('Tanggal', style: inter(12)),
              const SizedBox(height: 10),
              _dateField(),
              const SizedBox(height: 22),
              Text('Catatan (Opsional)', style: inter(12)),
              const SizedBox(height: 10),
              _noteField(),
            ]),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Simpan Transaksi',
            width: double.infinity,
            height: 50,
            fontSize: 16,
            radius: 10,
            textColor: Colors.white,
            onTap: _save,
            loading: _saving,
          ),
        ],
      ),
    );
  }

  Widget _toggle() {
    Widget tab(String label, bool selected, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: 33,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? kCardBg : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(label,
                  style: inter(12, weight: FontWeight.w600, color: selected ? const Color(0xFF006363) : const Color(0xFF5B5B5B))),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        tab('pengeluaran', _isExpense, () => setState(() => _isExpense = true)),
        tab('pemasukan', !_isExpense, () => setState(() => _isExpense = false)),
      ]),
    );
  }

  Widget _categories() {
    return LayoutBuilder(builder: (context, cons) {
      final columns = cons.maxWidth < 280 ? 3 : 4;
      final w = (cons.maxWidth - (columns - 1) * 6) / columns;
      return Wrap(spacing: 6, runSpacing: 14, children: [
        for (final e in expenseCats.entries)
          GestureDetector(
            onTap: () => setState(() => _category = e.key),
            child: SizedBox(
              width: w,
              child: Column(children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _category == e.key ? AppColors.primary : const Color(0xFFCDE3DE),
                  ),
                  child: Icon(e.value.icon, size: 26, color: _category == e.key ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 6),
                FittedBox(fit: BoxFit.scaleDown, child: Text(e.value.label, style: inter(12))),
              ]),
            ),
          ),
      ]);
    });
  }

  Widget _dateField() => InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 47,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border, width: 2),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 22),
            const SizedBox(width: 14),
            Text('${two(_date.month)}/${two(_date.day)}/${_date.year}', style: inter(16)),
            const Spacer(),
            Text('>', style: inter(14)),
          ]),
        ),
      );

  Widget _noteField() => Container(
        height: 92,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border, width: 2),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.article_outlined, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _note,
              maxLines: null,
              maxLength: 255,
              style: inter(14),
              cursorColor: AppColors.primary,
              decoration: const InputDecoration(isDense: true, border: InputBorder.none, counterText: ''),
            ),
          ),
        ]),
      );
}
