import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/design_frame.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DesignFrame(background: AppColors.bg, children: [
      pos(142, 126, Text('Hello!', textAlign: TextAlign.center, style: inter(40, weight: FontWeight.w700)), w: 116),
      pos(0, 194, Text('Selamat Datang di Kaskita', textAlign: TextAlign.center, style: inter(25)), w: 393),
      pos(
        123,
        310,
        const CroppedImage(
          asset: 'assets/images/logo_kaskita.png',
          width: 148,
          height: 138,
          radius: 24,
          wFactor: 2.3288,
          hFactor: 1.3558,
          leftFactor: -0.6689,
          topFactor: -0.1779,
        ),
      ),
      pos(
        53,
        620,
        PrimaryButton(
          label: 'Log in',
          width: 287,
          height: 68,
          fontSize: 25,
          textColor: Colors.white,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
        ),
      ),
      pos(
        53,
        715,
        PrimaryButton(
          label: 'Sign up',
          width: 287,
          height: 68,
          fontSize: 25,
          textColor: Colors.white,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen())),
        ),
      ),
    ]);
  }
}
