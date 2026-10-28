import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../widgets/app_widgets.dart';

int _amountValue(Object? value) =>
    value is num ? value.round() : int.tryParse('$value') ?? 0;

String _displayDate(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  return '${date.day} ${bulan[date.month - 1]} ${date.year}';
}

class KasTargetScreen extends StatefulWidget {
  final VoidCallback onBack;

  const KasTargetScreen({super.key, required this.onBack});

  @override
  State<KasTargetScreen> createState() => _KasTargetScreenState();
}

class _KasTargetScreenState extends State<KasTargetScreen> {
  List<Map<String, dynamic>> _targets = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTargets();
  }

  Future<void> _loadTargets() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final targets = await Api.targets();
      if (!mounted) return;
      setState(() {
        _targets = targets;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _createTarget() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const KasTargetCreateScreen()),
    );
    if (created == true) _loadTargets();
  }

  Future<void> _openTarget(Map<String, dynamic> target) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => KasTargetDetailScreen(id: _amountValue(target['id'])),
      ),
    );
    if (changed == true) _loadTargets();
  }

  @override
  Widget build(BuildContext context) {
    final total = _targets.fold<int>(
      0,
      (sum, target) => sum + _amountValue(target['currentAmount']),
    );
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        onRefresh: _loadTargets,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            _TargetHero(
              title: 'KasTarget',
              subtitle: 'Yuk, wujudkan impianmu dengan menabung.',
              back: widget.onBack,
              footer: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Dana Seluruhnya',
                      style: inter(14,
                          color: Colors.white.withValues(alpha: .82))),
                  const SizedBox(height: 4),
                  Text(rupiah(total),
                      style: inter(22,
                          weight: FontWeight.w700, color: Colors.white)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('KasTarget kamu',
                      style: inter(18, weight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  if (_loading)
                    const _TargetLoading()
                  else if (_error != null)
                    _TargetMessage(
                      icon: Icons.cloud_off_outlined,
                      title: 'KasTarget belum bisa dimuat',
                      message: _error!,
                      action: 'Coba lagi',
                      onTap: _loadTargets,
                    )
                  else ...[
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 340;
                        final width = isNarrow
                            ? constraints.maxWidth
                            : (constraints.maxWidth - 12) / 2;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: width,
                              height: 161,
                              child: _AddTargetCard(onTap: _createTarget),
                            ),
                            for (final target in _targets)
                              SizedBox(
                                width: width,
                                height: 161,
                                child: _TargetCard(
                                  target: target,
                                  onTap: () => _openTarget(target),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    if (_targets.isEmpty) ...[
                      const SizedBox(height: 22),
                      _TargetMessage(
                        icon: Icons.savings_outlined,
                        title: 'Belum ada target tabungan',
                        message:
                            'Mulai dari satu impian kecil. Yuk buat KasTarget pertamamu!',
                        action: 'Buat KasTarget',
                        onTap: _createTarget,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KasTargetCreateScreen extends StatefulWidget {
  const KasTargetCreateScreen({super.key});

  @override
  State<KasTargetCreateScreen> createState() => _KasTargetCreateScreenState();
}

class _KasTargetCreateScreenState extends State<KasTargetCreateScreen> {
  final _name = TextEditingController();
  final _initialAmount = TextEditingController();
  final _targetAmount = TextEditingController();
  DateTime? _deadline;
  int _walletBalance = 0;
  bool _loadingBalance = true;
  bool _saving = false;
  String? _balanceError;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  @override
  void dispose() {
    _name.dispose();
    _initialAmount.dispose();
    _targetAmount.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    setState(() {
      _loadingBalance = true;
      _balanceError = null;
    });
    try {
      final result = await Api.dashboard(isoDate(today()));
      if (!mounted) return;
      setState(() {
        _walletBalance = _amountValue(result['balance']);
        _loadingBalance = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _balanceError = error.message;
        _loadingBalance = false;
      });
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 30)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 20),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context)
                .colorScheme
                .copyWith(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (selected != null) setState(() => _deadline = selected);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final targetAmount =
        int.tryParse(_targetAmount.text.replaceAll('.', '')) ?? 0;
    final initialAmount =
        int.tryParse(_initialAmount.text.replaceAll('.', '')) ?? 0;
    if (name.isEmpty) {
      return showError(context, 'Nama KasTarget wajib diisi');
    }
    if (targetAmount <= 0) {
      return showError(context, 'Masukkan jumlah target lebih dari 0');
    }
    if (initialAmount > targetAmount) {
      return showError(context, 'Setoran awal tidak boleh melebihi target');
    }
    if (_deadline == null) {
      return showError(context, 'Pilih tanggal pencapaian');
    }
    if (_balanceError != null || _loadingBalance) {
      return showError(context, 'Saldo KasKita belum dapat diverifikasi');
    }
    if (initialAmount > _walletBalance) {
      return showError(context, 'Saldo KasKita tidak mencukupi');
    }

    setState(() => _saving = true);
    try {
      await Api.createTarget(
        name: name,
        targetAmount: targetAmount,
        initialAmount: initialAmount,
        deadline: isoDate(_deadline!),
      );
      if (!mounted) return;
      final confirmed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const _KasTargetSuccessScreen()),
      );
      if (confirmed == true && mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) showError(context, error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _TargetHero(
            title: 'KasTarget',
            subtitle: 'Mari wujudkan mimpimu dengan menabung.',
            back: () => Navigator.of(context).pop(),
          ),
          Transform.translate(
            offset: const Offset(0, -18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ElevatedPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TargetInput(
                      label: 'Nama KasTarget',
                      controller: _name,
                      hint: 'Contoh: Traveling',
                      prefixIcon: Icons.edit_outlined,
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final initialAmount = _TargetInput(
                          label: 'Setoran Awal (opsional)',
                          controller: _initialAmount,
                          hint: 'Rp 0',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            ThousandsFormatter()
                          ],
                        );
                        final balance = _BalanceSummary(
                          label: 'Saldo KasKita',
                          amount: _walletBalance,
                          loading: _loadingBalance,
                          error: _balanceError,
                          onRetry: _loadBalance,
                        );
                        if (constraints.maxWidth < 340) {
                          return Column(
                            children: [
                              initialAmount,
                              const SizedBox(height: 14),
                              balance,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: initialAmount),
                            const SizedBox(width: 10),
                            Expanded(child: balance),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _TargetInput(
                      label: 'Jumlah yang ingin ditabung',
                      controller: _targetAmount,
                      hint: 'Rp 1.500.000',
                      prefixIcon: Icons.credit_card_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        ThousandsFormatter()
                      ],
                    ),
                    const SizedBox(height: 14),
                    _DateSelector(
                      label: 'Tanggal Pencapaian',
                      value: _deadline == null
                          ? null
                          : _displayDate(isoDate(_deadline!)),
                      onTap: _pickDeadline,
                    ),
                    if (_balanceError != null) ...[
                      const SizedBox(height: 10),
                      Text(_balanceError!,
                          style: inter(12, color: AppColors.error)),
                    ],
                    const SizedBox(height: 22),
                    _ActionButton(
                      label: 'Lanjut',
                      onTap: _save,
                      loading: _saving,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class KasTargetDetailScreen extends StatefulWidget {
  final int id;

  const KasTargetDetailScreen({super.key, required this.id});

  @override
  State<KasTargetDetailScreen> createState() => _KasTargetDetailScreenState();
}

class _KasTargetDetailScreenState extends State<KasTargetDetailScreen> {
  Map<String, dynamic>? _target;
  List<Map<String, dynamic>> _movements = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Api.targetDetail(widget.id);
      if (!mounted) return;
      setState(() {
        _target = result['target'] as Map<String, dynamic>;
        _movements = (result['movements'] as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _openFlow({required bool deposit}) async {
    if (_target == null) return;
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            _KasTargetFlowScreen(target: _target!, deposit: deposit),
      ),
    );
    if (updated == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final target = _target;
    final current = _amountValue(target?['currentAmount']);
    final goal = _amountValue(target?['targetAmount']);
    final progress = goal == 0 ? 0.0 : (current / goal).clamp(0.0, 1.0);
    final deadline = target?['deadline']?.toString() ?? '';
    final daysLeft =
        DateTime.tryParse(deadline)?.difference(DateTime.now()).inDays;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            _TargetHero(
              title: target?['name']?.toString() ?? 'KasTarget',
              subtitle: target == null ? null : 'Target\n${rupiah(goal)}',
              back: () => Navigator.of(context).pop(),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: _TargetMessage(
                  icon: Icons.cloud_off_outlined,
                  title: 'Detail target belum bisa dimuat',
                  message: _error!,
                  action: 'Coba lagi',
                  onTap: _load,
                ),
              )
            else if (target != null) ...[
              Transform.translate(
                offset: const Offset(0, -18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ElevatedPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Terkumpul',
                            style: inter(14, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(rupiah(current),
                            style: inter(23,
                                weight: FontWeight.w700,
                                color: AppColors.primary)),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 9,
                            backgroundColor: AppColors.bg,
                            valueColor:
                                const AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('0%',
                                style:
                                    inter(11, color: AppColors.textSecondary)),
                            Text(rupiah(goal),
                                style: inter(12, weight: FontWeight.w600)),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text('Deadline',
                                    style: inter(12,
                                        color: AppColors.textSecondary))),
                            Text(_displayDate(deadline),
                                style: inter(12, weight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.schedule_outlined,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text('Waktu tersisa',
                                    style: inter(12,
                                        color: AppColors.textSecondary))),
                            Text(
                              daysLeft == null
                                  ? '-'
                                  : daysLeft < 0
                                      ? 'Terlewat'
                                      : '$daysLeft hari lagi',
                              style: inter(12,
                                  weight: FontWeight.w600,
                                  color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final deposit = _OutlinedAction(
                      icon: Icons.add_circle_outline,
                      title: 'Tambah Dana',
                      subtitle: 'Top up tabungan',
                      onTap: () => _openFlow(deposit: true),
                    );
                    final withdraw = _OutlinedAction(
                      icon: Icons.south_west_outlined,
                      title: 'Tarik Dana',
                      subtitle: 'Ambil tabungan',
                      onTap: () => _openFlow(deposit: false),
                    );
                    if (constraints.maxWidth < 340) {
                      return Column(
                        children: [
                          deposit,
                          const SizedBox(height: 10),
                          withdraw,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: deposit),
                        const SizedBox(width: 12),
                        Expanded(child: withdraw),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SummaryStrip(
                  target: goal,
                  current: current,
                  remaining: _amountValue(target['remainingAmount']),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text('Riwayat tabungan',
                    style: inter(17, weight: FontWeight.w700)),
              ),
              if (_movements.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: _TargetMessage(
                    icon: Icons.savings_outlined,
                    title: 'Belum ada aktivitas',
                    message:
                        'Setoran dan penarikan KasTarget akan muncul di sini.',
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: _MovementList(movements: _movements),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: _EncouragementCard(progress: progress),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KasTargetFlowScreen extends StatefulWidget {
  final Map<String, dynamic> target;
  final bool deposit;

  const _KasTargetFlowScreen({required this.target, required this.deposit});

  @override
  State<_KasTargetFlowScreen> createState() => _KasTargetFlowScreenState();
}

class _KasTargetFlowScreenState extends State<_KasTargetFlowScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  int _walletBalance = 0;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  int get _targetBalance => _amountValue(widget.target['currentAmount']);
  int get _available => widget.deposit ? _walletBalance : _targetBalance;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadWallet() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Api.dashboard(isoDate(today()));
      if (!mounted) return;
      setState(() {
        _walletBalance = _amountValue(result['balance']);
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    final amount = int.tryParse(_amount.text.replaceAll('.', '')) ?? 0;
    if (amount <= 0) return showError(context, 'Masukkan jumlah lebih dari 0');
    if (amount > _available) {
      return showError(context,
          'Saldo ${widget.deposit ? 'KasKita' : 'KasTarget'} tidak mencukupi');
    }
    if (_error != null || _loading) {
      return showError(context, 'Saldo belum dapat diverifikasi');
    }
    setState(() => _saving = true);
    try {
      final targetId = _amountValue(widget.target['id']);
      if (widget.deposit) {
        await Api.depositToTarget(targetId,
            amount: amount, note: _note.text.trim());
      } else {
        await Api.withdrawFromTarget(targetId,
            amount: amount, note: _note.text.trim());
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) showError(context, error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetName = widget.target['name']?.toString() ?? 'KasTarget';
    final title = widget.deposit ? 'Tambah Dana' : 'Tarik Dana';
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _TargetHero(
            title: title,
            centered: true,
            back: () => Navigator.of(context).pop(),
          ),
          Transform.translate(
            offset: const Offset(0, -18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ElevatedPanel(
                child: Column(
                  children: [
                    _AccountRow(
                      icon: Icons.account_balance_wallet_outlined,
                      title: widget.deposit ? 'KasKita' : targetName,
                      subtitle:
                          widget.deposit ? 'Dompet utama' : 'Tabungan target',
                      amount: widget.deposit ? _walletBalance : _targetBalance,
                    ),
                    const Divider(height: 20),
                    _AccountRow(
                      icon: Icons.savings_outlined,
                      title: widget.deposit ? targetName : 'KasKita',
                      subtitle:
                          widget.deposit ? 'Target tabungan' : 'Dompet utama',
                      amount: widget.deposit ? _targetBalance : _walletBalance,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saldo ${widget.deposit ? 'KasKita' : 'KasTarget'}',
                      style: inter(13, weight: FontWeight.w600),
                    ),
                    if (_loading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary),
                      )
                    else
                      Text(rupiah(_available),
                          style: inter(13, weight: FontWeight.w700)),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 6),
                  Text(_error!, style: inter(12, color: AppColors.error)),
                  TextButton(
                      onPressed: _loadWallet, child: const Text('Coba lagi')),
                ],
                const SizedBox(height: 12),
                _TargetInput(
                  label: 'Jumlah',
                  controller: _amount,
                  hint: 'Rp 0',
                  prefixIcon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    ThousandsFormatter()
                  ],
                ),
                const SizedBox(height: 16),
                _TargetInput(
                  label: 'Catatan (opsional)',
                  controller: _note,
                  hint: 'Isi catatan',
                  prefixIcon: Icons.notes_outlined,
                  maxLength: 255,
                ),
                const SizedBox(height: 24),
                _ActionButton(
                  label: 'Lanjut',
                  onTap: _submit,
                  loading: _saving,
                  enabled: !_loading && _error == null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KasTargetSuccessScreen extends StatelessWidget {
  const _KasTargetSuccessScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _TargetHero(
              title: 'KasTarget',
              subtitle: 'Mari wujudkan mimpimu dengan menabung.',
              back: () => Navigator.of(context).pop(false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 116,
                      height: 116,
                      decoration: const BoxDecoration(
                        color: AppColors.card,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.card,
                      ),
                      child: const Icon(Icons.celebration_outlined,
                          size: 58, color: AppColors.primary),
                    ),
                    const SizedBox(height: 24),
                    Text('Sukses!', style: inter(28, weight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                      'Yeay! KasTarget kamu berhasil dibuat.',
                      textAlign: TextAlign.center,
                      style: inter(14, color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                    Text('Ayo lihat KasTarget mu',
                        style: inter(18, weight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    _ActionButton(
                      label: 'Lihat KasTarget',
                      onTap: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetHero extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback back;
  final Widget? footer;
  final bool centered;

  const _TargetHero({
    required this.title,
    required this.back,
    this.subtitle,
    this.footer,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      height: 267,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.splash],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          const Positioned(right: -32, top: 34, child: _HeroOrbit(size: 178)),
          if (!centered)
            const Positioned(right: 26, top: 92, child: _HeroArt()),
          Padding(
            padding: EdgeInsets.fromLTRB(12, top + 8, 20, 18),
            child: Column(
              crossAxisAlignment: centered
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 38,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: back,
                      tooltip: 'Kembali',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 25),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: Align(
                    alignment:
                        centered ? Alignment.center : Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(right: centered ? 0 : 112),
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: centered ? TextAlign.center : TextAlign.left,
                        style: inter(34,
                            weight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: EdgeInsets.only(right: centered ? 0 : 118, top: 3),
                    child: Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: centered ? TextAlign.center : TextAlign.left,
                      style: inter(13,
                          weight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: .9)),
                    ),
                  ),
                if (footer != null) ...[
                  const Spacer(),
                  footer!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroOrbit extends StatelessWidget {
  final double size;
  const _HeroOrbit({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border:
            Border.all(color: Colors.white.withValues(alpha: .12), width: 1.4),
      ),
    );
  }
}

class _HeroArt extends StatelessWidget {
  const _HeroArt();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      height: 118,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 8,
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Icon(Icons.savings_rounded, color: Colors.white, size: 62),
          const Positioned(
              right: 8,
              top: 13,
              child:
                  Icon(Icons.auto_awesome, color: Color(0xFFFFE08A), size: 18)),
          const Positioned(
              left: 7,
              top: 29,
              child: Icon(Icons.circle, color: Color(0xFFB8F2E8), size: 10)),
          const Positioned(
              right: 21,
              bottom: 4,
              child: Icon(Icons.circle, color: Color(0xFFFFE08A), size: 8)),
        ],
      ),
    );
  }
}

class _ElevatedPanel extends StatelessWidget {
  final Widget child;
  const _ElevatedPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.primary.withValues(alpha: .16)),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}

class _AddTargetCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddTargetCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.primary.withValues(alpha: .35)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.splash]),
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 34),
              ),
              const SizedBox(height: 14),
              Text(
                'Tambah KasTarget',
                textAlign: TextAlign.center,
                style: inter(13, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  final Map<String, dynamic> target;
  final VoidCallback onTap;
  const _TargetCard({required this.target, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final goal = _amountValue(target['targetAmount']);
    final current = _amountValue(target['currentAmount']);
    final progress = goal == 0 ? 0.0 : (current / goal).clamp(0.0, 1.0);
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.primary.withValues(alpha: .25)),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                target['name']?.toString() ?? 'KasTarget',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: inter(15,
                    weight: FontWeight.w700, color: AppColors.primary),
              ),
              const SizedBox(height: 6),
              Text('Terkumpul',
                  style: inter(10, color: AppColors.textSecondary)),
              Text(
                rupiah(current),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: inter(12, weight: FontWeight.w700),
              ),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.bg,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Target ${rupiah(goal)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: inter(9, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetLoading extends StatelessWidget {
  const _TargetLoading();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget placeholder() => Container(
              height: 161,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadii.card),
                boxShadow: AppShadows.card,
              ),
            );
        if (constraints.maxWidth < 340) return placeholder();
        return Row(
          children: [
            Expanded(child: placeholder()),
            const SizedBox(width: 12),
            Expanded(child: placeholder()),
          ],
        );
      },
    );
  }
}

class _TargetMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onTap;

  const _TargetMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ElevatedPanel(
      child: Column(
        children: [
          Icon(icon, size: 34, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(title,
              textAlign: TextAlign.center,
              style: inter(15, weight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(message,
              textAlign: TextAlign.center,
              style: inter(12, color: AppColors.textSecondary)),
          if (action != null && onTap != null) ...[
            const SizedBox(height: 12),
            _ActionButton(label: action!, onTap: onTap!),
          ],
        ],
      ),
    );
  }
}

class _TargetInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final int? maxLength;

  const _TargetInput({
    required this.label,
    required this.controller,
    required this.hint,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters = const [],
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: inter(12,
                weight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          style: inter(14, weight: FontWeight.w600),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                inter(13, color: AppColors.textSecondary.withValues(alpha: .7)),
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, size: 19, color: AppColors.primary),
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.medium),
              borderSide:
                  BorderSide(color: AppColors.primary.withValues(alpha: .35)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.medium),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _BalanceSummary extends StatelessWidget {
  final String label;
  final int amount;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  const _BalanceSummary({
    required this.label,
    required this.amount,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: inter(12,
                weight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.medium),
          child: InkWell(
            onTap: error == null ? null : onRetry,
            borderRadius: BorderRadius.circular(AppRadii.medium),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.medium),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: .35)),
              ),
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
                      error == null ? rupiah(amount) : 'Coba lagi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: inter(12, weight: FontWeight.w700),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;
  const _DateSelector(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: inter(12,
                weight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.medium),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.medium),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.medium),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: .35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined,
                      size: 19, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      value ?? 'Pilih tanggal pencapaian',
                      style: inter(13,
                          color: value == null
                              ? AppColors.textSecondary
                              : AppColors.textPrimary),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool loading;
  final bool enabled;

  const _ActionButton({
    required this.label,
    required this.onTap,
    this.loading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && !loading;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.medium),
        child: Ink(
          decoration: BoxDecoration(
            color: active ? null : AppColors.disabled,
            gradient: active
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [AppColors.primary, AppColors.splash],
                  )
                : null,
            borderRadius: BorderRadius.circular(AppRadii.medium),
            boxShadow: active ? AppShadows.card : null,
          ),
          child: InkWell(
            onTap: active ? onTap : null,
            borderRadius: BorderRadius.circular(AppRadii.medium),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(label,
                      style: inter(15,
                          weight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlinedAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _OutlinedAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadii.medium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.medium),
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.medium),
            border: Border.all(color: AppColors.primary.withValues(alpha: .4)),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: inter(11, weight: FontWeight.w700)),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: inter(9, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final int target;
  final int current;
  final int remaining;
  const _SummaryStrip(
      {required this.target, required this.current, required this.remaining});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.flag_outlined, 'Target', target),
      (Icons.account_balance_wallet_outlined, 'Terkumpul', current),
      (Icons.pie_chart_outline_rounded, 'Sisa Target', remaining),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.medium),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  border: index == 0
                      ? null
                      : const Border(left: BorderSide(color: AppColors.bg)),
                ),
                child: Column(
                  children: [
                    Icon(items[index].$1, color: AppColors.primary, size: 21),
                    const SizedBox(height: 4),
                    Text(items[index].$2,
                        style: inter(10, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      rupiah(items[index].$3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: inter(10, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MovementList extends StatelessWidget {
  final List<Map<String, dynamic>> movements;
  const _MovementList({required this.movements});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final movement in movements)
          Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadii.medium),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: movement['type'] == 'deposit'
                        ? AppColors.bg
                        : const Color(0xFFFFE1DE),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    movement['type'] == 'deposit'
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    color: movement['type'] == 'deposit'
                        ? AppColors.primary
                        : AppColors.error,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movement['type'] == 'deposit'
                            ? 'Tambah dana'
                            : 'Tarik dana',
                        style: inter(13, weight: FontWeight.w600),
                      ),
                      Text(
                        movement['note']?.toString().isNotEmpty == true
                            ? movement['note'].toString()
                            : 'Tanpa catatan',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: inter(11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${movement['type'] == 'deposit' ? '+' : '-'}${rupiah(_amountValue(movement['amount']))}',
                  style: inter(
                    12,
                    weight: FontWeight.w700,
                    color: movement['type'] == 'deposit'
                        ? AppColors.primary
                        : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int amount;
  const _AccountRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppColors.primary, size: 23),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: inter(13, weight: FontWeight.w700)),
              Text(subtitle, style: inter(10, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(rupiah(amount), style: inter(12, weight: FontWeight.w700)),
      ],
    );
  }
}

class _EncouragementCard extends StatelessWidget {
  final double progress;
  const _EncouragementCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.medium),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite_outline_rounded,
              color: Color(0xFFE98484), size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progress >= 1
                      ? 'Yeay, targetmu tercapai!'
                      : 'Kamu pasti bisa mencapai goal ini!',
                  style: inter(12, weight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  'Jangan lupa menabung. Sedikit demi sedikit, lama-lama menjadi bukit.',
                  style: inter(10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
