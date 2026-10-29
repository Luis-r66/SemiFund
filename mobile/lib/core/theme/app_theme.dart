import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.ink,
      onPrimary: AppColors.paper,
      secondary: AppColors.ink,
      onSecondary: AppColors.paper,
      surface: AppColors.paper,
      onSurface: AppColors.ink,
      error: AppColors.bad,
      onError: AppColors.paper,
      outline: AppColors.line,
    );

    final textTheme = TextTheme(
      displayLarge: AppTextStyles.display,
      displayMedium: AppTextStyles.h1,
      displaySmall: AppTextStyles.h2,
      headlineMedium: AppTextStyles.h3,
      headlineSmall: AppTextStyles.h4,
      titleLarge: AppTextStyles.h2,
      titleMedium: AppTextStyles.h4,
      titleSmall: AppTextStyles.smallSemibold,
      bodyLarge: AppTextStyles.body,
      bodyMedium: AppTextStyles.small,
      bodySmall: AppTextStyles.tiny,
      labelLarge: AppTextStyles.button,
      labelMedium: AppTextStyles.smallMedium,
      labelSmall: AppTextStyles.tinyMedium,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      fontFamily: AppTextStyles.sans,
      scaffoldBackgroundColor: AppColors.paper,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.h3,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.ink3),
        labelStyle: AppTextStyles.smallMedium.copyWith(color: AppColors.ink2),
        errorStyle: AppTextStyles.smallMedium.copyWith(color: AppColors.bad),
        border: _border(AppColors.line),
        enabledBorder: _border(AppColors.line),
        focusedBorder: _border(AppColors.ink, width: 1.4),
        errorBorder: _border(AppColors.bad),
        focusedErrorBorder: _border(AppColors.bad, width: 1.4),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.paper,
          disabledBackgroundColor: AppColors.ink,
          disabledForegroundColor: AppColors.paper,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.button,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: AppColors.paper,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.button,
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          textStyle: AppTextStyles.smallSemibold,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: AppTextStyles.small.copyWith(color: AppColors.paper),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.ink,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: AppTextStyles.h3,
        contentTextStyle: AppTextStyles.body.copyWith(color: AppColors.ink2),
      ),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
