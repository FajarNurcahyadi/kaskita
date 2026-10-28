import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/theme.dart';
import '../main.dart';
import '../widgets/app_widgets.dart';
import '../widgets/design_frame.dart';
import 'forgot_password_screen.dart';
import 'main_shell.dart';
import 'signup_screen.dart';
import 'verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  late final TapGestureRecognizer _signUpTap = TapGestureRecognizer()
    ..onTap = () => Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const SignUpScreen()));

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _signUpTap.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _email.text.trim();
    if (email.isEmpty || _password.text.isEmpty) {
      showError(context, 'Email dan kata sandi wajib diisi');
      return;
    }
    setState(() => _loading = true);
    try {
      await Api.login(email, _password.text);
      if (!mounted) return;
      goReplaceAll(context, const MainShell());
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.body?['needsVerification'] == true) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => VerificationScreen(email: email.toLowerCase(), purpose: OtpPurpose.register)));
      } else if (e.body?['needsTwoFactor'] == true) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => VerificationScreen(email: email.toLowerCase(), purpose: OtpPurpose.login)));
      } else {
        showError(context, e.message);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    if (isDesktop) {
      return DesignFrame(background: AppColors.bg, children: [
        pos(146, 82, Text('Login', textAlign: TextAlign.center, style: inter(40, weight: FontWeight.w700)), w: 116),
        pos(94, 156, Image.asset('assets/images/cat_login.png', width: 205, height: 205, fit: BoxFit.cover)),
        pos(40, 344, const FieldLabel('Email or Phone Number')),
        pos(40, 376, AppField(controller: _email, keyboardType: TextInputType.emailAddress)),
        pos(40, 440, const FieldLabel('Password')),
        pos(40, 469, AppField(controller: _password, obscure: true)),
        pos(
          248,
          531,
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
            child: Text('Forgot Password', style: inter(15)),
          ),
        ),
        pos(40, 589, PrimaryButton(label: 'Login', onTap: _login, loading: _loading)),
        pos(0, 665, const DividerWithText('or continue with')),
        pos(132, 711, const SocialRow()),
        pos(
          0,
          773,
          Text.rich(
            TextSpan(style: inter(15), children: [
              const TextSpan(text: 'Don’t have an account? '),
              TextSpan(text: 'Sign Up', style: inter(15, style: FontStyle.italic), recognizer: _signUpTap),
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
                  children: [
                    Text('Login', style: inter(34, weight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    Container(
                      width: 170,
                      height: 170,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Image.asset(
                        'assets/images/cat_login.png',
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const FieldLabel('Email or Phone Number'),
                    ),
                    const SizedBox(height: 8),
                    AppField(
                      controller: _email,
                      width: double.infinity,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const FieldLabel('Password'),
                    ),
                    const SizedBox(height: 8),
                    AppField(
                      controller: _password,
                      width: double.infinity,
                      obscure: true,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        ),
                        child: Text('Forgot Password', style: inter(14, color: AppColors.primary)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: 'Login',
                      width: double.infinity,
                      height: 56,
                      onTap: _login,
                      loading: _loading,
                    ),
                    const SizedBox(height: 18),
                    const DividerWithText('or continue with'),
                    const SizedBox(height: 14),
                    const SocialRow(),
                    const SizedBox(height: 18),
                    Text.rich(
                      TextSpan(style: inter(14), children: [
                        const TextSpan(text: 'Don’t have an account? '),
                        TextSpan(
                          text: 'Sign Up',
                          style: inter(14, weight: FontWeight.w700, color: AppColors.primary),
                          recognizer: _signUpTap,
                        ),
                      ]),
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
