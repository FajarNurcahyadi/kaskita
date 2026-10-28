import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/theme.dart';
import '../main.dart';
import '../widgets/app_widgets.dart';
import '../widgets/design_frame.dart';
import '../widgets/otp_input.dart';
import 'login_screen.dart';
import 'main_shell.dart';
import 'new_password_screen.dart';
import 'signup_success_screen.dart';

enum OtpPurpose { register, reset, login }

class VerificationScreen extends StatefulWidget {
  final String email;
  final OtpPurpose purpose;
  const VerificationScreen({super.key, required this.email, required this.purpose});
  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  String _code = '';
  bool _loading = false;

  Future<void> _submit() async {
    if (_code.length != 4) return showError(context, 'Masukkan 4 digit kode');
    setState(() => _loading = true);
    try {
      if (widget.purpose == OtpPurpose.register) {
        await Api.verifyOtp(widget.email, _code);
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignUpSuccessScreen()));
      } else if (widget.purpose == OtpPurpose.login) {
        await Api.verifyLoginOtp(widget.email, _code);
        if (!mounted) return;
        goReplaceAll(context, const MainShell());
      } else {
        final token = await Api.verifyResetOtp(widget.email, _code);
        if (!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => NewPasswordScreen(resetToken: token)));
      }
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    try {
      await Api.resendOtp(widget.email, widget.purpose.name);
      if (mounted) showInfo(context, 'Kode baru sudah dikirim');
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    if (isDesktop) {
      return DesignFrame(background: AppColors.bg, children: [
        pos(33, 99, const BigTitle('Verifikasi'), w: 250),
        pos(38, 146, Text('Masukan kode untuk melanjutkan', style: inter(15, weight: FontWeight.w700, color: AppColors.primary))),
        pos(19, 180, Image.asset('assets/images/inbox.png', width: 271, height: 200, fit: BoxFit.cover)),
        pos(
          0,
          423,
          Text('Kami sudah mengirimkan kode\nke gmail anda',
              textAlign: TextAlign.center, style: inter(18, weight: FontWeight.w700)),
          w: 393,
        ),
        pos(38, 485, OtpInput(onChanged: (v) => _code = v)),
        pos(
          40,
          569,
          PrimaryButton(
            label: 'Lanjut',
            width: 333,
            fontSize: 18,
            textColor: const Color(0xFFF9F9F9),
            onTap: _submit,
            loading: _loading,
          ),
        ),
        pos(
          44,
          641,
          GestureDetector(
            onTap: _resend,
            child: Text.rich(TextSpan(style: inter(18, weight: FontWeight.w700), children: [
              const TextSpan(text: 'Tidak menerima kode? '),
              TextSpan(
                  text: 'Kirim ulang',
                  style: inter(18, weight: FontWeight.w800, color: AppColors.primary, style: FontStyle.italic)),
            ])),
          ),
        ),
        pos(
          86,
          805,
          GestureDetector(
            onTap: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false),
            child: Row(children: [
              const Icon(Icons.arrow_back, size: 20),
              const SizedBox(width: 10),
              Text.rich(TextSpan(style: inter(18), children: [
                const TextSpan(text: 'Kembali untuk '),
                TextSpan(text: 'masuk', style: inter(18, weight: FontWeight.w600, style: FontStyle.italic)),
                const TextSpan(text: '?'),
              ])),
            ]),
          ),
        ),
      ]);
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
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
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Verifikasi', style: inter(32, weight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Masukan kode untuk melanjutkan',
                      style: inter(14, weight: FontWeight.w700, color: AppColors.primary),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Image.asset(
                        'assets/images/inbox.png',
                        width: 240,
                        height: 170,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Kami sudah mengirimkan kode\nke gmail anda',
                      textAlign: TextAlign.center,
                      style: inter(16, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 18),
                    OtpInput(onChanged: (v) => _code = v),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Lanjut',
                      width: double.infinity,
                      height: 56,
                      fontSize: 18,
                      textColor: const Color(0xFFF9F9F9),
                      onTap: _submit,
                      loading: _loading,
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: _resend,
                      child: Text.rich(
                        TextSpan(style: inter(14, weight: FontWeight.w700), children: [
                          const TextSpan(text: 'Tidak menerima kode? '),
                          TextSpan(
                            text: 'Kirim ulang',
                            style: inter(14, weight: FontWeight.w800, color: AppColors.primary, style: FontStyle.italic),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_back, size: 20),
                          const SizedBox(width: 8),
                          Text.rich(
                            TextSpan(style: inter(14), children: [
                              const TextSpan(text: 'Kembali untuk '),
                              TextSpan(
                                text: 'masuk',
                                style: inter(14, weight: FontWeight.w700, color: AppColors.primary),
                              ),
                              const TextSpan(text: '?'),
                            ]),
                          ),
                        ],
                      ),
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
