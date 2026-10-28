import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Tombol utama (radius 15).
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double width, height, fontSize, radius;
  final Color color, textColor;
  final bool loading;
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.width = 327,
    this.height = 54,
    this.fontSize = 20,
    this.radius = 15,
    this.color = AppColors.primary,
    this.textColor = Colors.black,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: loading ? null : onTap,
          child: Center(
            child: loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: textColor))
                : Text(label, style: inter(fontSize, weight: FontWeight.w700, color: textColor)),
          ),
        ),
      ),
    );
  }
}

/// Field outline teal (radius 8, tinggi 50). `obscure` => ada ikon mata.
class AppField extends StatefulWidget {
  final TextEditingController controller;
  final bool obscure;
  final TextInputType keyboardType;
  final double width;
  final String? hint;
  final ValueChanged<String>? onChanged;
  const AppField({
    super.key,
    required this.controller,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.width = 327,
    this.hint,
    this.onChanged,
  });

  @override
  State<AppField> createState() => _AppFieldState();
}

class _AppFieldState extends State<AppField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: widget.controller,
            obscureText: _hidden,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            style: inter(15, weight: FontWeight.w500),
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: widget.hint,
              hintStyle: inter(15, color: Colors.black45),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            ),
          ),
        ),
        if (widget.obscure)
          GestureDetector(
            onTap: () => setState(() => _hidden = !_hidden),
            child: Padding(
              padding: const EdgeInsets.only(right: 22, left: 8),
              child: Icon(_hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20, color: Colors.black),
            ),
          ),
      ]),
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String text;
  final double size;
  final Color color;
  const FieldLabel(this.text, {super.key, this.size = 15, this.color = Colors.black});
  @override
  Widget build(BuildContext context) =>
      Text(text, style: inter(size, weight: FontWeight.w700, color: color));
}

/// Judul besar 40px bold.
class BigTitle extends StatelessWidget {
  final String text;
  const BigTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) =>
      Text(text, style: inter(40, weight: FontWeight.w700).copyWith(height: 1.18));
}

/// Gambar dengan crop persentase seperti di Figma (logo KasKita).
class CroppedImage extends StatelessWidget {
  final String asset;
  final double width, height, radius;
  final double wFactor, hFactor, leftFactor, topFactor;
  const CroppedImage({
    super.key,
    required this.asset,
    required this.width,
    required this.height,
    required this.radius,
    required this.wFactor,
    required this.hFactor,
    required this.leftFactor,
    required this.topFactor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [BoxShadow(color: Color(0x40000000), offset: Offset(10, 10), blurRadius: 4)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(clipBehavior: Clip.hardEdge, children: [
          Positioned(
            left: leftFactor * width,
            top: topFactor * height,
            width: wFactor * width,
            height: hFactor * height,
            child: Image.asset(asset, fit: BoxFit.fill),
          ),
        ]),
      ),
    );
  }
}

/// 3 tombol sosial (Google, Apple, Facebook).
class SocialRow extends StatelessWidget {
  const SocialRow({super.key});

  Widget _circle(String asset, double iw, double ih) => Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Image.asset(asset, width: iw, height: ih, fit: BoxFit.cover),
      );

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        _circle('assets/images/google.png', 22, 22),
        const SizedBox(width: 20),
        _circle('assets/images/apple.png', 15.39, 18.9),
        const SizedBox(width: 19),
        _circle('assets/images/facebook.png', 22, 22),
      ]);
}

/// Garis kiri-kanan + teks tengah ("or continue with").
class DividerWithText extends StatelessWidget {
  final String text;
  const DividerWithText(this.text, {super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 393,
        height: 24,
        child: Stack(children: [
          Positioned(left: 0, top: 14, width: 94, child: Container(height: 1, color: Colors.black)),
          Positioned(left: 299, top: 14, width: 94, child: Container(height: 1, color: Colors.black)),
          Center(child: Text(text, style: inter(20))),
        ]),
      );
}

void showError(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg, style: inter(14, color: Colors.white)),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
}

void showInfo(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg, style: inter(14, color: Colors.white)),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
    ));
}
