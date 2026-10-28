import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/setting_widgets.dart';

class LoginHistoryScreen extends StatefulWidget {
  const LoginHistoryScreen({super.key});
  @override
  State<LoginHistoryScreen> createState() => _LoginHistoryScreenState();
}

class _LoginHistoryScreenState extends State<LoginHistoryScreen> {
  List<Map<String, dynamic>> _items = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await Api.logins();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  /// Tebakan sederhana dari User-Agent.
  (IconData, String) _device(String ua) {
    final u = ua.toLowerCase();
    if (u.contains('dart')) return (Icons.phone_android, 'Aplikasi KasKita');
    final os = u.contains('android')
        ? 'Android'
        : (u.contains('iphone') || u.contains('ipad'))
            ? 'iOS'
            : u.contains('windows')
                ? 'Windows'
                : (u.contains('mac os') || u.contains('macintosh'))
                    ? 'macOS'
                    : u.contains('linux')
                        ? 'Linux'
                        : 'Perangkat tidak dikenal';
    final browser = u.contains('edg/')
        ? 'Edge'
        : u.contains('firefox')
            ? 'Firefox'
            : u.contains('chrome')
                ? 'Chrome'
                : u.contains('safari')
                    ? 'Safari'
                    : '';
    final mobile = os == 'Android' || os == 'iOS';
    return (mobile ? Icons.smartphone : Icons.computer, browser.isEmpty ? os : '$browser di $os');
  }

  String _when(String iso) {
    final d = DateTime.parse(iso).toLocal();
    return '${d.day} ${bulan[d.month - 1]} ${d.year}, ${two(d.hour)}:${two(d.minute)}';
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
              isMobile ? 16 : 32, 32),
          children: [
            Row(children: [
              GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, size: 24, color: Color(0xFF006363))),
              const SizedBox(width: 10),
              Text('Riwayat Login', style: inter(24, weight: FontWeight.w600, color: const Color(0xFF006363))),
            ]),
            const SizedBox(height: 20),
            if (_loading)
              const Padding(padding: EdgeInsets.only(top: 100), child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Column(children: [
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
              ])
            else if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text('Belum ada riwayat login. Riwayat dicatat mulai dari login berikutnya.',
                    textAlign: TextAlign.center, style: inter(14, color: kSettingGrey)),
              )
            else
              SettingCard(children: [
                for (var i = 0; i < _items.length; i++)
                  Builder(builder: (_) {
                    final d = _device((_items[i]['userAgent'] as String?) ?? '');
                    return SettingTile(
                      icon: d.$1,
                      title: d.$2,
                      subtitle: '${i == 0 ? 'Terbaru • ' : ''}${_when(_items[i]['at'] as String)}',
                    );
                  }),
              ]),
          ],
        ),
      ),
    );
  }
}
