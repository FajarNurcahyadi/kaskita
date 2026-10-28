import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/tx_widgets.dart';

/// Tab 2 - Riwayat Transaksi (filter bulan + Semua/Pengeluaran/Pemasukan).
class HistoryScreen extends StatefulWidget {
  final VoidCallback onBack;
  const HistoryScreen({super.key, required this.onBack});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late DateTime _month = DateTime(today().year, today().month);
  String _filter = 'all';
  List<Map<String, dynamic>> _items = [];
  num _income = 0, _expense = 0;
  bool _loading = true;
  String? _error;

  static const _shadow = [BoxShadow(color: Color(0x40000000), offset: Offset(1, 1), blurRadius: 4)];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Api.transactions(monthKey(_month), type: _filter);
      if (!mounted) return;
      final s = r['summary'] as Map<String, dynamic>;
      setState(() {
        _items = (r['items'] as List).cast<Map<String, dynamic>>();
        _income = s['income'] as num;
        _expense = s['expense'] as num;
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

  void _reload() {
    setState(() => _loading = true);
    _load();
  }

  void _shift(int delta) {
    _month = DateTime(_month.year, _month.month + delta);
    _reload();
  }

  Future<void> _confirmDelete(Map<String, dynamic> tx) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus transaksi?'),
        content: Text('${metaFor(tx['category'] as String).label} • ${rupiah(tx['amount'] as num)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.deleteTransaction(tx['id'] as int);
      if (mounted) showInfo(context, 'Transaksi dihapus');
      _reload();
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    }
  }

  String _dayLabel(String iso) {
    final d = parseIso(iso);
    final diff = today().difference(d).inDays;
    final base = '${d.day} ${bulan[d.month - 1]}';
    if (diff == 0) return 'Hari ini, $base';
    if (diff == 1) return 'Kemarin, $base';
    if (diff > 1) return '$diff Hari yang lalu, $base';
    return base;
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
                  onTap: widget.onBack, child: const Icon(Icons.arrow_back, size: 24, color: AppColors.primary)),
              const SizedBox(width: 10),
              Text('Riwayat Transaksi', style: inter(24, weight: FontWeight.w600, color: const Color(0xFF006363))),
            ]),
            const SizedBox(height: 16),
            _monthBar(),
            const SizedBox(height: 8),
            _filterBar(),
            const SizedBox(height: 16),
            _summary(),
            const SizedBox(height: 16),
            ..._body(),
          ],
        ),
      ),
    );
  }

  Widget _monthBar() => Container(
        height: 45,
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10), boxShadow: _shadow),
        child: Row(children: [
          InkWell(
              onTap: () => _shift(-1),
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Text('<', style: inter(16, color: Colors.white)))),
          Expanded(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.white),
              const SizedBox(width: 10),
              Text('${bulan[_month.month - 1]}/${_month.year}', style: inter(16, color: Colors.white)),
            ]),
          ),
          InkWell(
              onTap: () => _shift(1),
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Text('>', style: inter(16, color: Colors.white)))),
        ]),
      );

  Widget _filterBar() {
    Widget tab(String label, String value) {
      final selected = _filter == value;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_filter == value) return;
            _filter = value;
            _reload();
          },
          child: Container(
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.bg : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(label,
                style: inter(12, weight: FontWeight.w600, color: selected ? const Color(0xFF006363) : Colors.white)),
          ),
        ),
      );
    }

    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4.5),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10), boxShadow: _shadow),
      child: Row(children: [tab('Semua', 'all'), tab('Pengeluaran', 'expense'), tab('Pemasukan', 'income')]),
    );
  }

  Widget _summary() => Container(
        height: 74,
        decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(10), boxShadow: _shadow),
        child: Row(children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 17),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pemasukan', style: inter(12)),
                const SizedBox(height: 4),
                FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('+Rp.${thousands(_income.round().toString())}',
                        style: inter(16, weight: FontWeight.w700, color: const Color(0xFF27500A)))),
              ]),
            ),
          ),
          Container(width: 1, height: 49, color: Colors.black),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pengeluaran', style: inter(12)),
                const SizedBox(height: 4),
                FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('-Rp.${thousands(_expense.round().toString())}',
                        style: inter(16, weight: FontWeight.w700, color: kExpenseRed))),
              ]),
            ),
          ),
        ]),
      );

  List<Widget> _body() {
    if (_loading) {
      return const [Padding(padding: EdgeInsets.only(top: 80), child: Center(child: CircularProgressIndicator()))];
    }
    if (_error != null) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Column(children: [
            Text(_error!, textAlign: TextAlign.center, style: inter(16)),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Coba lagi', width: 160, height: 46, fontSize: 15, textColor: Colors.white, onTap: _reload),
          ]),
        ),
      ];
    }
    if (_items.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Text('Belum ada transaksi di bulan ini', textAlign: TextAlign.center, style: inter(14, color: const Color(0xFF5B5B5B))),
        ),
      ];
    }

    final widgets = <Widget>[];
    String? lastDate;
    for (final t in _items) {
      final date = t['date'] as String;
      if (date != lastDate) {
        lastDate = date;
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 8),
          child: Text(_dayLabel(date), style: inter(12, weight: FontWeight.w700, color: const Color(0xFF5B5B5B))),
        ));
      }
      widgets.add(Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: _shadow),
        child: TxTile(tx: t, coloredExpense: true, onLongPress: () => _confirmDelete(t)),
      ));
    }
    widgets.add(Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text('Tahan lama sebuah transaksi untuk menghapusnya',
          textAlign: TextAlign.center, style: inter(11, color: const Color(0xFF5B5B5B))),
    ));
    return widgets;
  }
}
