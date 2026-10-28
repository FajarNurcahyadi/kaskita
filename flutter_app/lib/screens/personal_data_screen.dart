import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/avatar.dart';
import '../widgets/setting_widgets.dart';

class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({super.key});
  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
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

  Future<void> _save(Map<String, dynamic> data) async {
    try {
      final p = await Api.updateProfile(data);
      if (!mounted) return;
      setState(() => _p = p);
      showInfo(context, 'Data tersimpan');
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    }
  }

  Future<void> _editText(String label, String field, String current,
      {TextInputType? keyboard, bool digitsOnly = false, int? maxLength, String? message}) async {
    final r = await showFormDialog(
      context,
      title: label,
      message: message,
      fields: [FormFieldSpec('v', label, initial: current, keyboard: keyboard, digitsOnly: digitsOnly, maxLength: maxLength)],
    );
    if (r != null) _save({field: r['v']!.trim()});
  }

  Future<void> _editBirthDate() async {
    final cur = (_p!['birthDate'] as String);
    final picked = await showDatePicker(
      context: context,
      initialDate: cur.isEmpty ? DateTime(2000, 1, 1) : parseIso(cur),
      firstDate: DateTime(1900),
      lastDate: today(),
    );
    if (picked != null) _save({'birthDate': isoDate(picked)});
  }

  String _nik(String v) => v.isEmpty
      ? ''
      : [for (var i = 0; i < v.length; i += 4) v.substring(i, i + 4 > v.length ? v.length : i + 4)].join(' ');

  String _date(String iso) {
    if (iso.isEmpty) return '';
    final d = parseIso(iso);
    return '${two(d.day)} ${bulan[d.month - 1]} ${d.year}';
  }

  Widget _row(IconData icon, String label, String value, {VoidCallback? onTap}) => SettingTile(
        icon: icon,
        title: value.isEmpty ? 'Belum diisi' : value,
        onTap: onTap,
        label: label,
        muted: value.isEmpty,
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
              Text('Data Diri', style: inter(24, weight: FontWeight.w600, color: const Color(0xFF006363))),
            ]),
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
              const SizedBox(height: 28),
              Center(child: Avatar(name: _p!['name'] as String, size: 69, color: kSettingGreen)),
              const SizedBox(height: 14),
              Center(child: Text(_p!['name'] as String, style: inter(16, weight: FontWeight.w600))),
              const SizedBox(height: 32),
              SettingCard(children: [
                _row(Icons.account_circle_outlined, 'Nama Lengkap', _p!['name'] as String,
                    onTap: () => _editText('Nama Lengkap', 'name', _p!['name'] as String, maxLength: 100)),
                _row(Icons.badge_outlined, 'NIK (KTP)', _nik(_p!['nik'] as String),
                    onTap: () => _editText('NIK (KTP)', 'nik', _p!['nik'] as String,
                        keyboard: TextInputType.number, digitsOnly: true, maxLength: 16, message: '16 digit angka. Kosongkan untuk menghapus.')),
                _row(Icons.cake_outlined, 'Tanggal Lahir', _date(_p!['birthDate'] as String), onTap: _editBirthDate),
                _row(Icons.call_outlined, 'Nomor Hp', _p!['phone'] as String,
                    onTap: () => _editText('Nomor Hp', 'phone', _p!['phone'] as String, keyboard: TextInputType.phone, maxLength: 20)),
                _row(Icons.mail_outline, 'Email', _p!['email'] as String),
                _row(Icons.work_outline, 'Jabatan', _p!['jobTitle'] as String,
                    onTap: () => _editText('Jabatan', 'jobTitle', _p!['jobTitle'] as String, maxLength: 50)),
                _row(Icons.storefront_outlined, 'Nama Usaha', _p!['businessName'] as String,
                    onTap: () => _editText('Nama Usaha', 'businessName', _p!['businessName'] as String, maxLength: 80)),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}
