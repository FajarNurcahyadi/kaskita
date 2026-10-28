import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/theme.dart';
import '../main.dart';
import '../widgets/app_widgets.dart';
import '../widgets/design_frame.dart';
import 'login_screen.dart';
import 'password_success_screen.dart';

class NewPasswordScreen extends StatefulWidget {
  final String resetToken;
  const NewPasswordScreen({super.key, required this.resetToken});
  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  bool get _valid => _pass.text.length >= 8 && _pass.text == _confirm.text;

  @override
  void dispose() {
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await Api.resetPassword(widget.resetToken, _pass.text);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PasswordSuccessScreen()));
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
        pos(38, 79, const BigTitle('Buat Kata Sandi Baru'), w: 220),
        pos(40, 181, Text('Buat Kata Sandi yang Unik', style: inter(18, weight: FontWeight.w700, color: AppColors.primary))),
        pos(37, 244, Image.asset('assets/images/card_postal.png', width: 319, height: 217, fit: BoxFit.cover)),
        pos(33, 483, const FieldLabel('Kata Sandi Baru')),
        pos(33, 515, AppField(controller: _pass, obscure: true, onChanged: (_) => setState(() {}))),
        pos(33, 579, const FieldLabel('Konfirmasi Kata Sandi')),
        pos(33, 605, AppField(controller: _confirm, obscure: true, onChanged: (_) => setState(() {}))),
        pos(
          33,
          675,
          PrimaryButton(
            label: 'Lanjut',
            width: 333,
            fontSize: 18,
            color: _valid ? AppColors.primary : AppColors.disabled,
            onTap: _valid
                ? _submit
                : () => showError(context, 'Kata sandi minimal 8 karakter dan harus sama'),
            loading: _loading,
          ),
        ),
        pos(
          0,
          801,
          GestureDetector(
            onTap: () => goReplaceAll(context, const LoginScreen()),
            child: Text('Atur Ulang Kata Sandi Nanti?',
                textAlign: TextAlign.center, style: inter(18, weight: FontWeight.w700)),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Buat Kata Sandi Baru', style: inter(30, weight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text('Buat Kata Sandi yang Unik', style: inter(14, weight: FontWeight.w700, color: AppColors.primary)),
                    const SizedBox(height: 14),
                    Center(
                      child: Image.asset(
                        'assets/images/card_postal.png',
                        width: 240,
                        height: 180,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const FieldLabel('Kata Sandi Baru'),
                    const SizedBox(height: 8),
                    AppField(
                      controller: _pass,
                      width: double.infinity,
                      obscure: true,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    const FieldLabel('Konfirmasi Kata Sandi'),
                    const SizedBox(height: 8),
                    AppField(
                      controller: _confirm,
                      width: double.infinity,
                      obscure: true,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Lanjut',
                      width: double.infinity,
                      height: 56,
                      fontSize: 18,
                      color: _valid ? AppColors.primary : AppColors.disabled,
                      onTap: _valid
                          ? _submit
                          : () => showError(context, 'Kata sandi minimal 8 karakter dan harus sama'),
                      loading: _loading,
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: GestureDetector(
                        onTap: () => goReplaceAll(context, const LoginScreen()),
                        child: Text(
                          'Atur Ulang Kata Sandi Nanti?',
                          textAlign: TextAlign.center,
                          style: inter(14, weight: FontWeight.w700),
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
