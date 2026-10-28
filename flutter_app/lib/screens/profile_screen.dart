import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/theme.dart';
import '../main.dart';
import '../widgets/app_widgets.dart';
import '../widgets/avatar.dart';
import '../widgets/setting_widgets.dart';
import 'personal_data_screen.dart';
import 'security_screen.dart';
import 'welcome_screen.dart';

/// Tab 5 - Profil.
class ProfileScreen extends StatefulWidget {
  final VoidCallback onBack;
  const ProfileScreen({super.key, required this.onBack});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _load();
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Keluar')),
        ],
      ),
    );
    if (ok != true) return;
    await Api.logout();
    if (mounted) goReplaceAll(context, const WelcomeScreen());
  }

  String _subtitle(Map<String, dynamic> p) {
    final job = (p['jobTitle'] as String).trim();
    final biz = (p['businessName'] as String).trim();
    if (job.isNotEmpty && biz.isNotEmpty) return '$job. $biz';
    if (job.isNotEmpty || biz.isNotEmpty) return job.isNotEmpty ? job : biz;
    return p['email'] as String;
  }

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
              isMobile ? 16 : 32, 24),
          children: [
            Row(children: [
              GestureDetector(
                  onTap: widget.onBack, child: const Icon(Icons.arrow_back, size: 24, color: Color(0xFF006363))),
              const SizedBox(width: 6),
              Text('Profil', style: inter(24, weight: FontWeight.w600, color: const Color(0xFF006363))),
            ]),
            const SizedBox(height: 24),
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
              Container(
                padding: EdgeInsets.all(isMobile ? 18 : 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: kSettingBorder),
                ),
                child: Row(children: [
                  Avatar(name: _p!['name'] as String, size: 69, color: kSettingGreen),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_p!['name'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: inter(16, weight: FontWeight.w600)),
                      const SizedBox(height: 6),
                        Text(_subtitle(_p!),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: inter(12, color: kSettingGrey)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              SettingCard(children: [
                SettingTile(
                  icon: Icons.account_circle_outlined,
                  title: 'Data Diri',
                  subtitle: 'Ubah data pribadi & profil usaha',
                  onTap: () => _open(const PersonalDataScreen()),
                ),
                SettingTile(
                  icon: Icons.shield_outlined,
                  title: 'Keamanan',
                  subtitle: 'Kata sandi, PIN, dan privasi',
                  onTap: () => _open(const SecurityScreen()),
                ),
                SettingTile(
                  icon: Icons.notifications_none,
                  title: 'Notifikasi',
                  subtitle: 'Atur pengingat & update komunitas',
                  onTap: () => showInfo(context, 'Pengaturan notifikasi belum ada di desain Figma'),
                ),
                SettingTile(
                  icon: Icons.help_outline,
                  title: 'Pusat Bantuan',
                  subtitle: 'FAQ dan dukungan aplikasi',
                  onTap: () => showInfo(context, 'Pusat Bantuan belum ada di desain Figma'),
                ),
                SettingTile(icon: Icons.logout, title: 'Keluar', danger: true, onTap: _logout, trailing: const SizedBox.shrink()),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}
