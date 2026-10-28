import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Avatar bulat berisi inisial nama.
class Avatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  const Avatar({super.key, required this.name, this.size = 38, this.color});

  static const _palette = [
    Color(0xFF008B8B), Color(0xFF5B8DB8), Color(0xFFD85A30),
    Color(0xFF7E57C2), Color(0xFF2E7D32), Color(0xFFC2185B),
  ];

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final a = parts.first.substring(0, 1).toUpperCase();
    final b = parts.length > 1 ? parts[1].substring(0, 1).toUpperCase() : '';
    return '$a$b';
  }

  @override
  Widget build(BuildContext context) {
    final bg = color ?? _palette[name.codeUnits.fold<int>(0, (a, b) => a + b) % _palette.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
      child: Text(_initials, style: inter(size * 0.38, weight: FontWeight.w600, color: Colors.white)),
    );
  }
}
