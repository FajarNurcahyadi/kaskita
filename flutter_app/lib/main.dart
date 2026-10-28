import 'package:flutter/material.dart';
import 'core/api.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // Token ditolak server -> kembali ke Welcome.
  Api.onUnauthorized = () => navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()), (_) => false);
  runApp(const KasKitaApp());
}

class KasKitaApp extends StatelessWidget {
  const KasKitaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'KasKita',
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        builder: (context, child) {
          final isDesktop = MediaQuery.sizeOf(context).width >= 900;

          return Container(
            color: isDesktop ? const Color(0xFFEAF8F5) : AppColors.bg,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: isDesktop ? null : 430,
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 1320 : 430,
                  minHeight: isDesktop ? 760 : 0,
                ),
                padding: isDesktop
                    ? const EdgeInsets.all(24)
                    : EdgeInsets.zero,
                child: DecoratedBox(
                  decoration: isDesktop
                      ? BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1C0F172A),
                              offset: Offset(0, 18),
                              blurRadius: 35,
                            ),
                          ],
                        )
                      : const BoxDecoration(),
                  child: ClipRRect(
                    borderRadius:
                        isDesktop ? BorderRadius.circular(28) : BorderRadius.zero,
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          );
        },
        home: const SplashScreen(),
      );
}

/// Helper navigasi: ganti seluruh stack.
Future<T?> goReplaceAll<T>(BuildContext context, Widget page) =>
    Navigator.of(context).pushAndRemoveUntil<T>(
        MaterialPageRoute(builder: (_) => page), (_) => false);
