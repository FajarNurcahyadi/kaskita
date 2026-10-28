import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';

const kSettingBorder = Color(0xFFC8DBD7);
const kSettingGreen = Color(0xFF0F6E56);
const kSettingRed = Color(0xFF993C1D);
const kSettingGrey = Color(0xFF5F5E5A);

/// Kartu putih membulat berisi beberapa baris (dipisah garis tipis).
class SettingCard extends StatelessWidget {
  final List<Widget> children;
  const SettingCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rows.add(const Divider(height: 1, thickness: 1, indent: 4, endIndent: 4, color: kSettingBorder));
      rows.add(children[i]);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: kSettingBorder),
      ),
      child: Column(children: rows),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
        child: Text(text, style: inter(12, weight: FontWeight.w600, color: kSettingGrey)),
      );
}

/// Satu baris pengaturan: ikon bulat + judul + keterangan + penutup ('>' / switch).
class SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool danger;
  final Widget? trailing;
  /// Kalau diisi: tampil sebagai baris data (label kecil di atas, nilai di bawah).
  final String? label;
  final bool muted;
  const SettingTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.danger = false,
    this.trailing,
    this.label,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = danger ? kSettingRed : kSettingGreen;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: danger ? const Color(0xFFF8DDD5) : const Color(0xFFDDEFEA),
            ),
            child: Icon(icon, size: 24, color: accent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (label != null) ...[
                Text(label!, style: inter(12, color: kSettingGrey)),
                const SizedBox(height: 2),
                Text(title, style: inter(16, color: muted ? const Color(0xFF9A9A9A) : Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis),
              ] else
                Text(title, style: inter(16, weight: FontWeight.w600, color: danger ? kSettingRed : Colors.black)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: inter(12, color: kSettingGrey)),
              ],
            ]),
          ),
          if (trailing != null)
            trailing!
          else if (onTap != null)
            Padding(padding: const EdgeInsets.only(left: 8), child: Text('>', style: inter(12))),
        ]),
      ),
    );
  }
}

class FormFieldSpec {
  final String key, label;
  final bool obscure, digitsOnly;
  final int? maxLength;
  final TextInputType? keyboard;
  final String initial;
  const FormFieldSpec(this.key, this.label,
      {this.obscure = false, this.digitsOnly = false, this.maxLength, this.keyboard, this.initial = ''});
}

/// Dialog berisi beberapa field teks. Mengembalikan map key->nilai, atau null kalau dibatalkan.
Future<Map<String, String>?> showFormDialog(
  BuildContext context, {
  required String title,
  required List<FormFieldSpec> fields,
  String? message,
  String confirmLabel = 'Simpan',
  bool danger = false,
}) =>
    showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _FormDialog(title: title, fields: fields, message: message, confirmLabel: confirmLabel, danger: danger),
    );

class _FormDialog extends StatefulWidget {
  final String title, confirmLabel;
  final String? message;
  final List<FormFieldSpec> fields;
  final bool danger;
  const _FormDialog(
      {required this.title, required this.fields, required this.confirmLabel, required this.danger, this.message});
  @override
  State<_FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<_FormDialog> {
  late final Map<String, TextEditingController> _c = {
    for (final f in widget.fields) f.key: TextEditingController(text: f.initial)
  };

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (widget.message != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(widget.message!)),
          for (final f in widget.fields)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _c[f.key],
                obscureText: f.obscure,
                keyboardType: f.keyboard,
                maxLength: f.maxLength,
                inputFormatters: f.digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
                decoration: InputDecoration(labelText: f.label, counterText: ''),
              ),
            ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        TextButton(
          onPressed: () => Navigator.pop(context, {for (final e in _c.entries) e.key: e.value.text}),
          child: Text(widget.confirmLabel, style: widget.danger ? const TextStyle(color: kSettingRed) : null),
        ),
      ],
    );
  }
}
