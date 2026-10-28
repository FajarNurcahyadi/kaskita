import 'dart:async';
import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/theme.dart';
import '../main.dart';
import '../widgets/app_widgets.dart';
import '../widgets/design_frame.dart';
import 'main_shell.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  Future<void> _boot() async {
    final loggedIn = await Api.token();
    if (!mounted) return;
    _splashTimer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      goReplaceAll(
        context,
        loggedIn != null ? const MainShell() : const WelcomeScreen(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return DesignFrame(background: AppColors.splash, children: [
      pos(
        85,
        321,
        const CroppedImage(
          asset: 'assets/images/logo_kaskita.png',
          width: 222,
          height: 210,
          radius: 30,
          wFactor: 2.3511,
          hFactor: 1.3558,
          leftFactor: -0.6753,
          topFactor: -0.1779,
        ),
      ),
      pos(
        167,
        607,
        const SizedBox(
          width: 59,
          height: 59,
          child: CircularProgressIndicator(strokeWidth: 5, color: Colors.white),
        ),
      ),
      pos(
        89,
        736,
        SizedBox(
          width: 260,
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text('Rajut keuangan', style: inter(14, color: Colors.white)),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              Text('Rajut komunitas', style: inter(14, color: Colors.white)),
            ],
          ),
        ),
        w: 260,
      ),
    ]);
  }
}
