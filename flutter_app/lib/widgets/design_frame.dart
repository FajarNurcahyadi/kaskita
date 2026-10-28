import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Kanvas 393x852 (ukuran frame iPhone 16 di Figma) yang di-scale mengikuti
/// lebar layar, supaya posisi & ukuran elemen sama persis dengan desain.
/// Kalau layar lebih pendek / keyboard muncul, konten bisa di-scroll.
class DesignFrame extends StatelessWidget {
  final Color background;
  final List<Widget> children;
  const DesignFrame({super.key, required this.background, required this.children});

  static const double w = 393;
  static const double h = 852;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: isDesktop ? const Color(0xFFEAF6F3) : background,
        body: Center(
          child: Container(
            width: isDesktop ? 1100 : null,
            constraints: isDesktop
                ? const BoxConstraints(maxWidth: 1100, maxHeight: 760)
                : const BoxConstraints(),
            padding: isDesktop ? const EdgeInsets.all(20) : EdgeInsets.zero,
            child: DecoratedBox(
              decoration: isDesktop
                  ? BoxDecoration(
                      color: const Color(0xFFCAE8DF),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A0F172A),
                          blurRadius: 24,
                          offset: Offset(0, 14),
                        )
                      ],
                    )
                  : const BoxDecoration(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isDesktop ? 32 : 0),
                child: isDesktop
                    ? SizedBox(
                        height: 700,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: w,
                            height: h,
                            child: Stack(children: children),
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: FittedBox(
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: w,
                            height: h,
                            child: Stack(children: children),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shortcut Positioned dengan koordinat Figma.
Widget pos(double left, double top, Widget child, {double? w, double? h}) =>
    Positioned(left: left, top: top, width: w, height: h, child: child);
