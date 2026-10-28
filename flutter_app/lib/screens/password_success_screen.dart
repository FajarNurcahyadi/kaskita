import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../main.dart';
import '../widgets/app_widgets.dart';
import '../widgets/design_frame.dart';
import 'login_screen.dart';

class PasswordSuccessScreen extends StatelessWidget {
  const PasswordSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    if (isDesktop) {
      return DesignFrame(background: AppColors.bg, children: [
        pos(38, 79, const BigTitle('Kata Sandi Di Ubah!'), w: 220),
        pos(67, 199, Image.asset('assets/images/join_success.png', width: 259, height: 269, fit: BoxFit.cover)),
        pos(0, 497, Text('Kata Sandi Kamu Berhasil Dibuat', textAlign: TextAlign.center, style: inter(18, weight: FontWeight.w700, color: AppColors.primary)), w: 393),
        pos(0, 555, Text('Berhasil!', textAlign: TextAlign.center, style: inter(30, weight: FontWeight.w700)), w: 393),
        pos(
          38,
          623,
          PrimaryButton(
            label: 'Lanjut',
            width: 333,
            fontSize: 18,
            onTap: () => goReplaceAll(context, const LoginScreen()),
          ),
        ),
      ]);
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8F5),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A0F172A),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Kata Sandi Di Ubah!', style: inter(28, weight: FontWeight.w800), textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    Image.asset(
                      'assets/images/join_success.png',
                      width: 230,
                      height: 220,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Kata Sandi Kamu Berhasil Dibuat',
                      textAlign: TextAlign.center,
                      style: inter(16, weight: FontWeight.w700, color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text('Berhasil!', textAlign: TextAlign.center, style: inter(30, weight: FontWeight.w700)),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Lanjut',
                      width: double.infinity,
                      height: 56,
                      onTap: () => goReplaceAll(context, const LoginScreen()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
