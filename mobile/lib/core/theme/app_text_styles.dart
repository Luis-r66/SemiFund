import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Estilos derivados del prototipo React de Figma Make.
class AppTextStyles {
  const AppTextStyles._();

  static const String sans = 'Instrument Sans';
  static const String mono = 'Geist Mono';

  static TextStyle _base({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.ink,
    double? height,
    double? letterSpacing,
    bool monospace = false,
  }) {
    return TextStyle(
      fontFamily: monospace ? mono : sans,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontVariations: <FontVariation>[
        FontVariation('wght', weight.value.toDouble()),
      ],
    );
  }

  static TextStyle display = _base(
    size: 30,
    weight: FontWeight.w600,
    height: 1.08,
  );
  static TextStyle h1 = _base(size: 28, weight: FontWeight.w600, height: 1.12);
  static TextStyle h2 = _base(size: 21, weight: FontWeight.w600, height: 1.18);
  static TextStyle h3 = _base(size: 19, weight: FontWeight.w600, height: 1.2);
  static TextStyle h4 = _base(size: 16, weight: FontWeight.w600, height: 1.25);
  static TextStyle body = _base(
    size: 15,
    weight: FontWeight.w400,
    height: 1.35,
  );
  static TextStyle bodyMedium = _base(
    size: 15,
    weight: FontWeight.w500,
    height: 1.35,
  );
  static TextStyle bodySemibold = _base(
    size: 15,
    weight: FontWeight.w600,
    height: 1.35,
  );
  static TextStyle small = _base(
    size: 13,
    weight: FontWeight.w400,
    height: 1.35,
  );
  static TextStyle smallMedium = _base(
    size: 13,
    weight: FontWeight.w500,
    height: 1.35,
  );
  static TextStyle smallSemibold = _base(
    size: 13,
    weight: FontWeight.w600,
    height: 1.35,
  );
  static TextStyle tiny = _base(size: 12, weight: FontWeight.w400, height: 1.3);
  static TextStyle tinyMedium = _base(
    size: 12,
    weight: FontWeight.w500,
    height: 1.3,
  );
  static TextStyle tinySemibold = _base(
    size: 12,
    weight: FontWeight.w600,
    height: 1.3,
  );
  static TextStyle button = _base(size: 15, weight: FontWeight.w600);
  static TextStyle label = _base(
    size: 12,
    weight: FontWeight.w600,
    color: AppColors.ink3,
    letterSpacing: 0.8,
  );
  static TextStyle moneyLarge = _base(
    size: 34,
    weight: FontWeight.w500,
    monospace: true,
    height: 1,
    letterSpacing: -0.5,
  );
  static TextStyle moneyMedium = _base(
    size: 24,
    weight: FontWeight.w500,
    monospace: true,
    height: 1,
    letterSpacing: -0.3,
  );
  static TextStyle moneySmall = _base(
    size: 15,
    weight: FontWeight.w500,
    monospace: true,
    height: 1.2,
  );
  static TextStyle moneyTiny = _base(
    size: 13,
    weight: FontWeight.w400,
    monospace: true,
    height: 1.2,
  );

  static TextStyle withColor(TextStyle style, Color color) =>
      style.copyWith(color: color);
}
