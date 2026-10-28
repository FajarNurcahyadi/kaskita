import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/tx_widgets.dart';

/// Tab 0 - Beranda. [onNavigate] pindah tab (1 Tambah, 2 Riwayat, 4 Komunitas).
class DashboardScreen extends StatefulWidget {
  final ValueChanged<int> onNavigate;
  const DashboardScreen({super.key, required this.onNavigate});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await Api.dashboard(isoDate(today()));
      if (!mounted) return;
      setState(() {
        _data = d;
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
          padding: EdgeInsets.only(top: isMobile ? top + 18 : top + 40, bottom: 24),
          children: [
            if (_loading)
              const Padding(padding: EdgeInsets.only(top: 200), child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              _ErrorBox(message: _error!, onRetry: () {
                setState(() => _loading = true);
                _load();
              })
            else
              ..._content(_data!, isMobile: isMobile),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(Map<String, dynamic> d, {required bool isMobile}) {
    final recent = (d['recent'] as List).cast<Map<String, dynamic>>();
    return [
      _HeroBanner(
        balance: d['balance'] as num,
        income: d['income'] as num,
        expense: d['expense'] as num,
        compact: isMobile,
      ),
      const SizedBox(height: 26),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 22),
        child: Text('Aksi Cepat', style: inter(20, weight: FontWeight.w600)),
      ),
      const SizedBox(height: 14),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 22),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _QuickAction(icon: Icons.add_circle_outline, label: 'Tambah', primary: true, compact: isMobile, onTap: () => widget.onNavigate(1)),
            _QuickAction(
                icon: Icons.analytics_outlined,
                label: 'Analis',
                compact: isMobile,
                onTap: () => showInfo(context, 'Layar Analis menyusul di batch berikutnya')),
            _QuickAction(icon: Icons.update, label: 'Riwayat', compact: isMobile, onTap: () => widget.onNavigate(2)),
            _QuickAction(icon: Icons.groups, label: 'Komunitas', compact: isMobile, onTap: () => widget.onNavigate(4)),
          ],
        ),
      ),
      const SizedBox(height: 24),
      _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                'Analisis Bulan ini',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: inter(isMobile ? 15 : 16, weight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => showInfo(context, 'Layar Analis menyusul di batch berikutnya'),
              child: Text(
                'Lihat semua',
                style: inter(isMobile ? 13 : 16,
                    color: const Color(0xFF0F6E56)),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          _BarChart(days: (d['chart'] as List).cast<Map<String, dynamic>>()),
          const SizedBox(height: 10),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _Legend(color: AppColors.primary, label: 'Pemasukan'),
            _Legend(color: Color(0xFFE24B4A), label: 'Pengeluaran'),
          ]),
        ]),
      ),
      const SizedBox(height: 24),
      _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                'Transaksi Terbaru',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: inter(isMobile ? 15 : 16, weight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => widget.onNavigate(2),
              child: Text(
                'Lihat semua',
                style: inter(isMobile ? 13 : 16,
                    color: const Color(0xFF0F6E56)),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          if (recent.isEmpty) ...[
            Text('Belum ada transaksi. Yuk catat transaksi pertamamu!', style: inter(14)),
            const SizedBox(height: 14),
            PrimaryButton(
                label: 'Tambah Transaksi',
                width: double.infinity,
                height: 46,
                fontSize: 15,
                textColor: Colors.white,
                onTap: () => widget.onNavigate(1)),
          ] else
            for (final t in recent)
              Padding(padding: const EdgeInsets.only(bottom: 12), child: TxTile(tx: t, iconSize: 55)),
        ]),
      ),
    ];
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.symmetric(horizontal: MediaQuery.sizeOf(context).width < 700 ? 16 : 34),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(12)),
        child: child,
      );
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBox({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(34, 160, 34, 0),
        child: Column(children: [
          Text(message, textAlign: TextAlign.center, style: inter(16)),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Coba lagi', width: 160, height: 46, fontSize: 15, textColor: Colors.white, onTap: onRetry),
        ]),
      );
}

class _HeroBanner extends StatelessWidget {
  final num balance, income, expense;
  final bool compact;
  const _HeroBanner({required this.balance, required this.income, required this.expense, this.compact = false});

  Widget _stat(IconData icon, String label, Color labelColor, num value) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: compact ? 13 : 15, color: labelColor),
            const SizedBox(width: 4),
            Text(label, style: inter(compact ? 11 : 12, weight: FontWeight.w500, color: labelColor)),
          ]),
          const SizedBox(height: 6),
          FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(rupiah(value), style: inter(compact ? 13 : 15, weight: FontWeight.w600, color: Colors.white))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 170 : 185,
      margin: EdgeInsets.symmetric(horizontal: compact ? 16 : 22),
      padding: EdgeInsets.fromLTRB(18, compact ? 22 : 30, 18, compact ? 14 : 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF008B8B), Color(0xFF006767)],
        ),
        boxShadow: const [BoxShadow(color: Color(0x40000000), offset: Offset(0, 4), blurRadius: 2)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text('Saldo Anda', style: inter(compact ? 14 : 15, color: const Color(0xFFE9F8F5))),
        ),
        SizedBox(height: compact ? 8 : 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            rupiah(balance),
            style: inter(compact ? 22 : 24,
                weight: FontWeight.w600, color: Colors.white),
          ),
        ),
        const Spacer(),
        Container(height: 1, color: Colors.white24),
        SizedBox(height: compact ? 10 : 12),
        Row(children: [
          _stat(Icons.arrow_downward, 'Pemasukan', const Color(0xFFB0EEED), income),
          Container(width: 1, height: compact ? 36 : 45, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 12)),
          _stat(Icons.arrow_upward, 'Pengeluaran', const Color(0xFFFFDAD6), expense),
        ]),
      ]),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final bool compact;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap, this.primary = false, this.compact = false});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: compact ? 64 : 72,
          child: Column(children: [
            Container(
              width: compact ? 60 : 69,
              height: compact ? 54 : 61,
              decoration: BoxDecoration(
                color: primary ? AppColors.primary : kCardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: compact ? 26 : 33, color: primary ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 6),
            Text(label, style: inter(compact ? 11 : 12)),
          ]),
        ),
      );
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: inter(12, weight: FontWeight.w200)),
      ]);
}

/// Bar chart sederhana 4 hari terakhir (pemasukan teal, pengeluaran oranye).
class _BarChart extends StatelessWidget {
  final List<Map<String, dynamic>> days;
  const _BarChart({required this.days});

  @override
  Widget build(BuildContext context) {
    const areaH = 100.0;
    num maxV = 0;
    for (final d in days) {
      for (final k in ['income', 'expense']) {
        final v = d[k] as num;
        if (v > maxV) maxV = v;
      }
    }
    Widget bar(num v, Color c) {
      final h = maxV == 0 ? 2.0 : (v / maxV * areaH).clamp(2.0, areaH).toDouble();
      return Container(
        width: 18,
        height: h,
        decoration: BoxDecoration(color: c, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
      );
    }

    return Column(children: [
      SizedBox(
        height: areaH + 24,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (final d in days)
            Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                bar(d['income'] as num, AppColors.primary),
                const SizedBox(width: 6),
                bar(d['expense'] as num, const Color(0xFFD85A30)),
              ]),
              const SizedBox(height: 6),
              Text(_label(d['date'] as String), style: inter(10, color: const Color(0xFF374151))),
            ]),
        ]),
      ),
      if (maxV == 0)
        Padding(padding: const EdgeInsets.only(top: 6), child: Text('Belum ada data 4 hari terakhir', style: inter(12))),
    ]);
  }

  String _label(String iso) {
    final d = parseIso(iso);
    return '${d.day} ${bulanPendek[d.month - 1]}';
  }
}
