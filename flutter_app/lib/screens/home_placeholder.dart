import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../main.dart';
import '../widgets/app_widgets.dart';
import '../widgets/design_frame.dart';
import 'welcome_screen.dart';

/// Placeholder sampai dashboard KasKita dikodekan.
class HomePlaceholder extends StatelessWidget {
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return DesignFrame(background: AppColors.bg, children: [
      pos(0, 300, Text('Login berhasil 🎉', textAlign: TextAlign.center, style: inter(28, weight: FontWeight.w700)), w: 393),
      pos(0, 350, Text('Dashboard menyusul', textAlign: TextAlign.center, style: inter(16)), w: 393),
      pos(
        53,
        620,
        PrimaryButton(
          label: 'Logout',
          width: 287,
          height: 60,
          textColor: Colors.white,
          onTap: () async {
            final p = await SharedPreferences.getInstance();
            await p.remove('token');
            if (context.mounted) goReplaceAll(context, const WelcomeScreen());
          },
        ),
      ),
    ]);
  }
}
