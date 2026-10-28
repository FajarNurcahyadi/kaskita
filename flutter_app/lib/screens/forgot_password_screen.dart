import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/design_frame.dart';
import 'verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _email.text.trim().toLowerCase();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return showError(context, 'Format email tidak valid');
    }
    setState(() => _loading = true);
    try {
      await Api.forgotPassword(email);
      if (!mounted) return;
      Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VerificationScreen(email: email, purpose: OtpPurpose.reset)));
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    if (isDesktop) {
      return DesignFrame(background: AppColors.bg, children: [
        pos(40, 97, const BigTitle('Lupa\nPassword'), w: 208),
        pos(106, 200, Image.asset('assets/images/forgot.png', width: 267, height: 215, fit: BoxFit.cover)),
        pos(29, 444, const FieldLabel('Alamat Email', size: 18)),
        pos(
          261,
          444,
          GestureDetector(
            onTap: () => showInfo(context, 'Reset lewat nomor HP belum tersedia'),
            child: const FieldLabel('Nomor HP?', size: 18, color: AppColors.primary),
          ),
        ),
        pos(33, 474, AppField(controller: _email, keyboardType: TextInputType.emailAddress)),
        pos(
          33,
          534,
          PrimaryButton(label: 'Kirim Kode', fontSize: 18, textColor: Colors.white, onTap: _send, loading: _loading),
        ),
        pos(
          86,
          801,
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(children: [
              const Icon(Icons.arrow_back, size: 20),
              const SizedBox(width: 10),
              Text.rich(TextSpan(style: inter(18), children: [
                const TextSpan(text: 'Kembali untuk '),
                TextSpan(text: 'masuk', style: inter(18, weight: FontWeight.w700)),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lupa\nPassword', style: inter(32, weight: FontWeight.w800), textAlign: TextAlign.left),
                    const SizedBox(height: 18),
                    Center(
                      child: Image.asset(
                        'assets/images/forgot.png',
                        width: 220,
                        height: 180,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const FieldLabel('Alamat Email', size: 16),
                        GestureDetector(
                          onTap: () => showInfo(context, 'Reset lewat nomor HP belum tersedia'),
                          child: const FieldLabel('Nomor HP?', size: 14, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AppField(
                      controller: _email,
                      width: double.infinity,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: 'Kirim Kode',
                      width: double.infinity,
                      height: 56,
                      fontSize: 18,
                      textColor: Colors.white,
                      onTap: _send,
                      loading: _loading,
                    ),
                    const SizedBox(height: 22),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_back, size: 20),
                            const SizedBox(width: 8),
                            Text.rich(
                              TextSpan(style: inter(15), children: [
                                const TextSpan(text: 'Kembali untuk '),
                                TextSpan(text: 'masuk', style: inter(15, weight: FontWeight.w700, color: AppColors.primary)),
                                const TextSpan(text: '?'),
                              ]),
                            ),
                          ],
                        ),
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
