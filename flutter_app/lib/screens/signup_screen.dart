import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/design_frame.dart';
import 'login_screen.dart';
import 'verification_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _agree = false;
  bool _loading = false;
  late final TapGestureRecognizer _signInTap = TapGestureRecognizer()
    ..onTap = () => Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _signInTap.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final name = _name.text.trim();
    final email = _email.text.trim().toLowerCase();
    if (name.isEmpty) return showError(context, 'Nama wajib diisi');
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return showError(context, 'Format email tidak valid');
    }
    if (_password.text.length < 8) return showError(context, 'Kata sandi minimal 8 karakter');
    if (!_agree) return showError(context, 'Setujui Terms & Condition dulu');

    setState(() => _loading = true);
    try {
      await Api.register(name, email, _password.text);
      if (!mounted) return;
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => VerificationScreen(email: email, purpose: OtpPurpose.register)));
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
        pos(42, 137, const BigTitle('Buat Akun'), w: 309),
        pos(38, 216, const FieldLabel('Nama')),
        pos(38, 256, AppField(controller: _name)),
        pos(38, 328, const FieldLabel('Email')),
        pos(38, 360, AppField(controller: _email, keyboardType: TextInputType.emailAddress)),
        pos(40, 440, const FieldLabel('Kata Sandi')),
        pos(38, 468, AppField(controller: _password, obscure: true)),
        pos(
          40,
          536,
          GestureDetector(
            onTap: () => setState(() => _agree = !_agree),
            child: Row(children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: _agree ? AppColors.check : Colors.transparent,
                  border: _agree ? null : Border.all(color: Colors.black54, width: 1.5),
                ),
                child: _agree ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
              ),
              const SizedBox(width: 9),
              Text('Agree with Terms & Condition', style: inter(15)),
            ]),
          ),
        ),
        pos(40, 589, PrimaryButton(label: 'Sign Up', onTap: _signUp, loading: _loading)),
        pos(0, 667, const DividerWithText('or sign up with')),
        pos(132, 711, const SocialRow()),
        pos(
          0,
          773,
          Text.rich(
            TextSpan(style: inter(15), children: [
              const TextSpan(text: 'Already have an account? '),
              TextSpan(text: 'Sign In', style: inter(15, style: FontStyle.italic), recognizer: _signInTap),
            ]),
            textAlign: TextAlign.center,
          ),
          w: 393,
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
                    Text('Buat Akun', style: inter(34, weight: FontWeight.w800)),
                    const SizedBox(height: 20),
                    const FieldLabel('Nama'),
                    const SizedBox(height: 8),
                    AppField(controller: _name, width: double.infinity),
                    const SizedBox(height: 14),
                    const FieldLabel('Email'),
                    const SizedBox(height: 8),
                    AppField(
                      controller: _email,
                      width: double.infinity,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    const FieldLabel('Kata Sandi'),
                    const SizedBox(height: 8),
                    AppField(
                      controller: _password,
                      width: double.infinity,
                      obscure: true,
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: () => setState(() => _agree = !_agree),
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: _agree ? AppColors.check : Colors.transparent,
                              border: _agree ? null : Border.all(color: Colors.black54, width: 1.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: _agree ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('Agree with Terms & Condition', style: inter(14)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Sign Up',
                      width: double.infinity,
                      height: 56,
                      onTap: _signUp,
                      loading: _loading,
                    ),
                    const SizedBox(height: 18),
                    const DividerWithText('or sign up with'),
                    const SizedBox(height: 14),
                    Center(child: const SocialRow()),
                    const SizedBox(height: 18),
                    Center(
                      child: Text.rich(
                        TextSpan(style: inter(14), children: [
                          const TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Sign In',
                            style: inter(14, weight: FontWeight.w700, color: AppColors.primary),
                            recognizer: _signInTap,
                          ),
                        ]),
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
