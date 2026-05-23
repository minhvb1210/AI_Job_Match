import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'app_colors.dart';

class AppTheme {
  static ShadThemeData get light {
    return ShadThemeData(
      brightness: Brightness.light,
      colorScheme: const ShadSlateColorScheme.light(
        primary: AppColors.primary,
        background: AppColors.background,
        foreground: AppColors.textPrimary,
        card: AppColors.card,
        border: Color(0xFFE2E8F0),
        input: Color(0xFFE2E8F0),
        ring: AppColors.primary,
        secondary: AppColors.secondary,
        muted: Color(0xFFF1F5F9),
        mutedForeground: AppColors.textSecondary,
        accent: Color(0xFFF1F5F9),
        accentForeground: AppColors.textPrimary,
        destructive: AppColors.error,
        destructiveForeground: Colors.white,
      ),
      textTheme: ShadTextTheme.fromGoogleFont(
        GoogleFonts.inter,
      ),
      radius: const BorderRadius.all(Radius.circular(12)),
    );
  }

  static ShadThemeData get dark {
    return ShadThemeData(
      brightness: Brightness.dark,
      colorScheme: const ShadSlateColorScheme.dark(
        primary: Color(0xFF60A5FA),
        background: Color(0xFF0F172A),
        foreground: Colors.white,
        card: Color(0xFF1E293B),
        border: Color(0xFF334155),
        input: Color(0xFF334155),
        ring: Color(0xFF60A5FA),
      ),
      textTheme: ShadTextTheme.fromGoogleFont(
        GoogleFonts.inter,
      ),
      radius: const BorderRadius.all(Radius.circular(12)),
    );
  }
}
