import 'package:flutter/material.dart';
import '../core/theme.dart';

class BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const BottomNav({super.key, required this.index, required this.onTap});

  static const _items = <(IconData, String)>[
    (Icons.home_outlined, 'Beranda'),
    (Icons.density_medium, 'Transaksi'),
    (Icons.history, 'Riwayat'),
    (Icons.add_circle_outline, 'KasTarget'),
    (Icons.groups_outlined, 'Komunitas'),
    (Icons.person_outline, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x1F000000), blurRadius: 6, offset: Offset(0, -1))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: List.generate(_items.length, (i) {
              final selected = i == index;
              final color = selected ? AppColors.primary : const Color(0xFFAAAAAA);
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(_items[i].$1, size: 26, color: color),
                    const SizedBox(height: 2),
                    SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _items[i].$2,
                          maxLines: 1,
                          softWrap: false,
                          style: inter(11, weight: FontWeight.w600, color: color),
                        ),
                      ),
                    ),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
