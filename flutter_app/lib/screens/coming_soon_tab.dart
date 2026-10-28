import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/theme.dart';
import '../main.dart';
import '../widgets/app_widgets.dart';
import 'welcome_screen.dart';

/// Tab sementara untuk layar yang dikerjakan di batch berikutnya.
class ComingSoonTab extends StatelessWidget {
  final String title;
  final String note;
  final bool showLogout;
  const ComingSoonTab({super.key, required this.title, required this.note, this.showLogout = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 24),
            Text(title, style: inter(24, weight: FontWeight.w600, color: const Color(0xFF006363))),
            const SizedBox(height: 12),
            Text(note, style: inter(15)),
            const Spacer(),
            if (showLogout)
              PrimaryButton(
                label: 'Logout',
                width: double.infinity,
                height: 50,
                fontSize: 16,
                textColor: Colors.white,
                onTap: () async {
                  await Api.logout();
                  if (context.mounted) goReplaceAll(context, const WelcomeScreen());
                },
              ),
          ]),
        ),
      ),
    );
  }
}
