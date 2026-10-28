import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFFD1EBE6);
  static const card = Color(0xFFE9F8F5);
  static const splash = Color(0xFF028585);
  static const primary = Color(0xFF008B8B);
  static const disabled = Color(0xFFD9D9D9);
  static const check = Color(0xFF5996FF);
  static const error = Color(0xFFC62828);
  static const textPrimary = Color(0xFF173B39);
  static const textSecondary = Color(0xFF536B68);
}

class AppRadii {
  static const small = 8.0;
  static const medium = 12.0;
  static const card = 15.0;
  static const pill = 30.0;
}

class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
}

class AppShadows {
  static const card = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
}

/// Gaya teks Inter sesuai Figma.
TextStyle inter(double size,
        {FontWeight weight = FontWeight.w400,
        Color color = AppColors.textPrimary,
        FontStyle style = FontStyle.normal}) =>
    GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        fontStyle: style,
        height: 1.2);

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        surface: AppColors.card,
        error: AppColors.error,
      ),
      cardColor: AppColors.card,
      textTheme: GoogleFonts.interTextTheme(),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
