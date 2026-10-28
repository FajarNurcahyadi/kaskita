import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/theme.dart';
import '../main.dart';
import '../widgets/app_widgets.dart';
import '../widgets/setting_widgets.dart';
import 'login_history_screen.dart';
import 'welcome_screen.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});
  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  Map<String, dynamic>? _p;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await Api.profile();
      if (!mounted) return;
      setState(() {
        _p = p;
        _error = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _changePassword() async {
    final r = await showFormDialog(context, title: 'Ubah Kata Sandi', fields: const [
      FormFieldSpec('current', 'Kata sandi saat ini', obscure: true),
      FormFieldSpec('next', 'Kata sandi baru (min. 8 karakter)', obscure: true),
      FormFieldSpec('confirm', 'Ulangi kata sandi baru', obscure: true),
    ]);
    if (r == null) return;
    if (r['next']!.length < 8) return showError(context, 'Kata sandi baru minimal 8 karakter');
    if (r['next'] != r['confirm']) return showError(context, 'Konfirmasi kata sandi tidak sama');
    try {
      await Api.changePassword(r['current']!, r['next']!);
      if (mounted) showInfo(context, 'Kata sandi berhasil diubah');
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    }
  }

  Future<void> _changePin() async {
    final hasPin = _p!['hasPin'] == true;
    final r = await showFormDialog(context, title: hasPin ? 'Ubah PIN' : 'Atur PIN', fields: [
      if (hasPin) const FormFieldSpec('current', 'PIN saat ini', obscure: true, digitsOnly: true, maxLength: 6, keyboard: TextInputType.number),
      const FormFieldSpec('pin', 'PIN baru (6 digit)', obscure: true, digitsOnly: true, maxLength: 6, keyboard: TextInputType.number),
      const FormFieldSpec('confirm', 'Ulangi PIN baru', obscure: true, digitsOnly: true, maxLength: 6, keyboard: TextInputType.number),
    ]);
    if (r == null) return;
    if (r['pin']!.length != 6) return showError(context, 'PIN harus 6 digit');
    if (r['pin'] != r['confirm']) return showError(context, 'Konfirmasi PIN tidak sama');
    try {
      await Api.setPin(r['pin']!, currentPin: hasPin ? r['current'] : null);
      if (mounted) showInfo(context, 'PIN tersimpan');
      _load();
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    }
  }

  Future<void> _toggle({bool? biometric, bool? twoFactor}) async {
    try {
      final p = await Api.updateSecurity(biometric: biometric, twoFactor: twoFactor);
      if (!mounted) return;
      setState(() => _p = p);
      if (biometric == true) {
        showInfo(context, 'Tersimpan. Buka kunci biometrik di perangkat belum aktif di versi ini.');
      }
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    }
  }

  Future<void> _deleteAccount() async {
    final hasPin = _p!['hasPin'] == true;
    final r = await showFormDialog(
      context,
      title: 'Hapus Akun',
      message: 'Tindakan permanen. Semua transaksi, postingan, dan komentar kamu ikut terhapus dan tidak bisa dikembalikan.',
      confirmLabel: 'Hapus Akun',
      danger: true,
      fields: [
        const FormFieldSpec('password', 'Kata sandi', obscure: true),
        if (hasPin) const FormFieldSpec('pin', 'PIN', obscure: true, digitsOnly: true, maxLength: 6, keyboard: TextInputType.number),
      ],
    );
    if (r == null) return;
    try {
      await Api.deleteAccount(r['password']!, pin: hasPin ? r['pin'] : null);
      if (mounted) goReplaceAll(context, const WelcomeScreen());
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    }
  }

  Widget _switch(bool value, ValueChanged<bool> onChanged) => Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: kSettingGreen,
      );

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final isMobile = MediaQuery.sizeOf(context).width < 700;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 32, top + (isMobile ? 24 : 40),
              isMobile ? 16 : 32, 32),
          children: [
            Row(children: [
              GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, size: 24, color: Color(0xFF006363))),
              const SizedBox(width: 10),
              Text('Keamanan', style: inter(24, weight: FontWeight.w600, color: const Color(0xFF006363))),
            ]),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(padding: EdgeInsets.only(top: 120), child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(children: [
                  Text(_error!, textAlign: TextAlign.center, style: inter(16)),
                  const SizedBox(height: 16),
                  PrimaryButton(
                      label: 'Coba lagi',
                      width: 160,
                      height: 46,
                      fontSize: 15,
                      textColor: Colors.white,
                      onTap: () {
                        setState(() => _loading = true);
                        _load();
                      }),
                ]),
              )
            else ...[
              const SectionLabel('KATA SANDI & PIN'),
              SettingCard(children: [
                SettingTile(icon: Icons.key, title: 'Ubah Kata Sandi', onTap: _changePassword),
                SettingTile(
                  icon: Icons.badge_outlined,
                  title: _p!['hasPin'] == true ? 'Ubah PIN' : 'Atur PIN',
                  subtitle: 'PIN 6 digit untuk konfirmasi',
                  onTap: _changePin,
                ),
              ]),
              const SizedBox(height: 22),
              const SectionLabel('PROTEKSI TAMBAHAN'),
              SettingCard(children: [
                SettingTile(
                  icon: Icons.fingerprint,
                  title: 'Sidik Jari/ Face ID',
                  subtitle: 'Masuk lebih cepat & aman',
                  trailing: _switch(_p!['biometric'] == true, (v) => _toggle(biometric: v)),
                ),
                SettingTile(
                  icon: Icons.mark_email_read_outlined,
                  title: 'Verifikasi Dua Langkah',
                  subtitle: 'Kode OTP via email setiap login baru',
                  trailing: _switch(_p!['twoFactor'] == true, (v) => _toggle(twoFactor: v)),
                ),
              ]),
              const SizedBox(height: 22),
              const SectionLabel('LAINNYA'),
              SettingCard(children: [
                SettingTile(
                  icon: Icons.history,
                  title: 'Riwayat Login',
                  subtitle: 'Cek perangkat yang pernah masuk',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginHistoryScreen())),
                ),
                SettingTile(
                  icon: Icons.person_remove_outlined,
                  title: 'Hapus Akun',
                  subtitle: 'Tindakan permanen. Tidak bisa dibatalkan',
                  danger: true,
                  onTap: _deleteAccount,
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}
