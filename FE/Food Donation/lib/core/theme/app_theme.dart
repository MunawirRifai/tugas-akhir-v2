import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF1F5F9);

  static const Color primary = Color(0xFF10B981);
  static const Color primaryDark = Color(0xFF047857);
  static const Color primarySoft = Color(0xFFD1FAE5);

  static const Color teal = Color(0xFF14B8A6);

  static const Color accent = Color(0xFFF59E0B);
  static const Color accentDark = Color(0xFFD97706);
  static const Color accentSoft = Color(0xFFFEF3C7);

  static const Color danger = Color(0xFFEF4444);
  static const Color dangerSoft = Color(0xFFFEE2E2);

  static const Color border = Color(0xFFE5E7EB);

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF9CA3AF);
}

class AppSpacing {
  const AppSpacing._();

  static const double x0 = 0;
  static const double x0_5 = 4;
  static const double x1 = 8;
  static const double x1_5 = 12;
  static const double x2 = 16;
  static const double x2_5 = 20;
  static const double x3 = 24;
  static const double x4 = 32;
  static const double x5 = 40;
  static const double x6 = 48;
}

class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 26;
  static const double xxl = 32;
}

class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> brand = [
    BoxShadow(
      color: Color(0x3310B981),
      blurRadius: 26,
      offset: Offset(0, 12),
    ),
  ];

  static const List<BoxShadow> accent = [
    BoxShadow(
      color: Color(0x33F59E0B),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> danger = [
    BoxShadow(
      color: Color(0x2EEF4444),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];
}

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.teal,
      surface: AppColors.surface,
      error: AppColors.danger,
    );

    final TextTheme baseTextTheme = Typography.blackMountainView;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Poppins',
      textTheme: _textTheme(baseTextTheme),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          color: AppColors.textPrimary,
          fontSize: 18,
          height: 1.25,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(
          color: AppColors.textPrimary,
          size: 24,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x2,
          vertical: AppSpacing.x2,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
          height: 1.35,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.35,
          fontWeight: FontWeight.w500,
        ),
        helperStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          height: 1.35,
          fontWeight: FontWeight.w400,
        ),
        errorStyle: const TextStyle(
          color: AppColors.danger,
          fontSize: 12,
          height: 1.35,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: AppColors.primaryDark,
        suffixIconColor: AppColors.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(
            color: AppColors.danger,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(
            color: AppColors.danger,
            width: 1.6,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.textMuted.withValues(alpha: 0.28),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.72),
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x2,
            vertical: AppSpacing.x1_5,
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          disabledForegroundColor: AppColors.textMuted,
          side: const BorderSide(
            color: AppColors.border,
          ),
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x2,
            vertical: AppSpacing.x1_5,
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          disabledForegroundColor: AppColors.textMuted,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x1,
            vertical: AppSpacing.x1,
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.surfaceSoft,
        side: const BorderSide(
          color: AppColors.border,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x1,
          vertical: 6,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: AppColors.primaryDark,
          fontSize: 12,
          height: 1.2,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
          fontSize: 12,
          height: 1.2,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }

          return AppColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withValues(alpha: 0.30);
          }

          return AppColors.border;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        circularTrackColor: AppColors.primarySoft,
        linearTrackColor: AppColors.primarySoft,
      ),
      snackBarTheme: SnackBarThemeData(
        elevation: 0,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
          fontSize: 13,
          height: 1.35,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: AppColors.textPrimary,
          fontSize: 18,
          height: 1.25,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.45,
          fontWeight: FontWeight.w400,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: 24,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      headlineLarge: const TextStyle(
        fontFamily: 'Poppins',
        color: AppColors.textPrimary,
        fontSize: 32,
        height: 1.15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
      ),
      headlineMedium: const TextStyle(
        fontFamily: 'Poppins',
        color: AppColors.textPrimary,
        fontSize: 24,
        height: 1.18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
      headlineSmall: const TextStyle(
        fontFamily: 'Poppins',
        color: AppColors.textPrimary,
        fontSize: 20,
        height: 1.22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
      titleLarge: const TextStyle(
        fontFamily: 'Poppins',
        color: AppColors.textPrimary,
        fontSize: 18,
        height: 1.25,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: const TextStyle(
        fontFamily: 'Poppins',
        color: AppColors.textPrimary,
        fontSize: 15,
        height: 1.28,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: const TextStyle(
        fontFamily: 'Poppins',
        color: AppColors.textPrimary,
        fontSize: 13,
        height: 1.25,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: const TextStyle(
        fontFamily: 'Poppins',
        color: AppColors.textSecondary,
        fontSize: 15,
        height: 1.45,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: const TextStyle(
        fontFamily: 'Poppins',
        color: AppColors.textSecondary,
        fontSize: 13,
        height: 1.45,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: const TextStyle(
        fontFamily: 'Poppins',
        color: AppColors.textMuted,
        fontSize: 12,
        height: 1.40,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: const TextStyle(
        fontFamily: 'Poppins',
        color: AppColors.textPrimary,
        fontSize: 13,
        height: 1.2,
        fontWeight: FontWeight.w700,
      ),
      labelMedium: const TextStyle(
        fontFamily: 'Poppins',
        color: AppColors.textSecondary,
        fontSize: 12,
        height: 1.2,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: const TextStyle(
        fontFamily: 'Poppins',
        color: AppColors.textMuted,
        fontSize: 11,
        height: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}