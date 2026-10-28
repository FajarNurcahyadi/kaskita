import 'package:flutter/material.dart';
import '../core/format.dart';
import '../core/theme.dart';

class CatMeta {
  final String label;
  final IconData icon;
  const CatMeta(this.label, this.icon);
}

const expenseCats = <String, CatMeta>{
  'makanan': CatMeta('Makanan', Icons.restaurant),
  'transportasi': CatMeta('Transportasi', Icons.directions_car_outlined),
  'tagihan': CatMeta('Tagihan', Icons.bolt),
  'belanja': CatMeta('Belanja', Icons.shopping_cart_outlined),
  'perbaikan': CatMeta('Perbaikan', Icons.build),
  'lainnya': CatMeta('Lainnya', Icons.more_horiz),
};

const _incomeMeta = CatMeta('Pemasukan', Icons.payments_outlined);
CatMeta metaFor(String category) => expenseCats[category] ?? _incomeMeta;

const kExpenseRed = Color(0xFF993C1D);
const kIncomeGreen = Color(0xFF2E7D32);
const kCardBg = Color(0xFFE9F8F5);

/// Satu baris transaksi (dipakai di Dashboard dan Riwayat).
class TxTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  final double iconSize;
  final bool coloredExpense;
  final VoidCallback? onLongPress;
  const TxTile({
    super.key,
    required this.tx,
    this.iconSize = 45,
    this.coloredExpense = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = tx['type'] == 'income';
    final meta = metaFor(tx['category'] as String);
    final amount = tx['amount'] as num;
    final note = (tx['note'] as String?) ?? '';

    return InkWell(
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(10),
      child: Row(children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isIncome ? const Color(0xFFB0EEED) : const Color(0xFFFFD9D6),
          ),
          child: Icon(meta.icon, size: 24, color: isIncome ? const Color(0xFF0F6E56) : const Color(0xFFD93025)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(meta.label, style: inter(15), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (note.isNotEmpty)
              Text(note, style: inter(12, weight: FontWeight.w200), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
        const SizedBox(width: 8),
        Text(
          isIncome ? '+ ${rupiah(amount)}' : '- ${rupiah(amount).toUpperCase()}',
          style: inter(15,
              weight: FontWeight.w600,
              color: isIncome ? kIncomeGreen : (coloredExpense ? kExpenseRed : Colors.black)),
        ),
      ]),
    );
  }
}
