import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/formatters.dart';

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.dim = false,
    this.light = false,
  });

  final String name;
  final double size;
  final bool dim;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final Color background = dim || light ? AppColors.mist : AppColors.ink;
    final Color foreground = dim || light ? AppColors.ink3 : AppColors.paper;
    final double fontSize = size <= 42
        ? 13
        : size <= 52
        ? 15
        : 18;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(
        initials(name),
        style: AppTextStyles.tinySemibold.copyWith(
          color: foreground,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
