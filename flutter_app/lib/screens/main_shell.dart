import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../widgets/bottom_nav.dart';
import 'add_transaction_screen.dart';
import 'community_screen.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'kas_target_screen.dart';
import 'profile_screen.dart';

/// Kerangka setelah login: 6 tab sesuai Navigator di Figma.
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  void _go(int i) => setState(() => _index = i);

  Widget _tab() {
    switch (_index) {
      case 0:
        return DashboardScreen(key: const ValueKey('home'), onNavigate: _go);
      case 1:
        return AddTransactionScreen(
            key: const ValueKey('add'),
            onBack: () => _go(0),
            onSaved: () => _go(2));
      case 2:
        return HistoryScreen(
            key: const ValueKey('history'), onBack: () => _go(0));
      case 3:
        return KasTargetScreen(
            key: const ValueKey('kas-target'), onBack: () => _go(0));
      case 4:
        return const CommunityScreen(key: ValueKey('community'));
      default:
        return ProfileScreen(
            key: const ValueKey('profile'), onBack: () => _go(0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: _tab(),
        bottomNavigationBar: BottomNav(index: _index, onTap: _go),
      ),
    );
  }
}
