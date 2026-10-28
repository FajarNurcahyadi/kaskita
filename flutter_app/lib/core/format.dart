import 'package:flutter/services.dart';

const bulan = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
];
const bulanPendek = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

String thousands(String digits) {
  final b = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) b.write('.');
    b.write(digits[i]);
  }
  return b.toString();
}

/// 3500000 -> "Rp 3.500.000"
String rupiah(num v) => '${v < 0 ? '-' : ''}Rp ${thousands(v.abs().round().toString())}';

String two(int n) => n.toString().padLeft(2, '0');
String isoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
DateTime parseIso(String s) {
  final p = s.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

String monthKey(DateTime d) => '${d.year}-${two(d.month)}';

/// Hari ini (tanpa jam).
DateTime today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    if (digits.length > 12) digits = digits.substring(0, 12);
    final f = thousands(digits);
    return TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length));
  }
}
