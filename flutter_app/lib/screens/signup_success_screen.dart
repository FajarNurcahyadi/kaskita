import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../main.dart';
import '../widgets/app_widgets.dart';
import '../widgets/design_frame.dart';
import 'login_screen.dart';

class SignUpSuccessScreen extends StatelessWidget {
  const SignUpSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    if (isDesktop) {
      return DesignFrame(background: AppColors.bg, children: [
        pos(38, 79, const BigTitle('Akun Berhasil Dibuat'), w: 281),
        pos(160, 247, Text('Ayo Login', style: inter(15, weight: FontWeight.w700))),
        pos(136, 354, Container(width: 122, height: 37, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle))),
        pos(134, 264, Image.asset('assets/images/phoenix.png', width: 122, height: 119, fit: BoxFit.cover)),
        pos(0, 506, Text('Akun Kamu Berhasil dibuat', textAlign: TextAlign.center, style: inter(18, weight: FontWeight.w700, color: AppColors.primary)), w: 393),
        pos(0, 546, Text('Berhasil!', textAlign: TextAlign.center, style: inter(30, weight: FontWeight.w700)), w: 393),
        pos(
          38,
          623,
          PrimaryButton(
            label: 'Continue',
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
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
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
                    Text('Akun Berhasil Dibuat', style: inter(28, weight: FontWeight.w800), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Text('Ayo Login', style: inter(14, weight: FontWeight.w700, color: AppColors.primary)),
                    const SizedBox(height: 18),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(28)),
                      ),
                      child: Image.asset(
                        'assets/images/phoenix.png',
                        width: 110,
                        height: 110,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Akun Kamu Berhasil dibuat',
                      textAlign: TextAlign.center,
                      style: inter(16, weight: FontWeight.w700, color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text('Berhasil!', textAlign: TextAlign.center, style: inter(30, weight: FontWeight.w700)),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Continue',
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
