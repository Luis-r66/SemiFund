import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 52,
    this.showLabel = true,
    this.light = false,
  });

  final double size;
  final bool showLabel;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: light ? AppColors.paper : AppColors.ink,
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: Icon(
            LucideIcons.sprout,
            color: light ? AppColors.ink : AppColors.paper,
            size: size * 0.5,
          ),
        ),
        if (showLabel) ...<Widget>[
          const SizedBox(height: 16),
          Text(
            'SEMIFUND',
            style: AppTextStyles.label.copyWith(
              letterSpacing: 1.3,
              color: AppColors.ink3,
            ),
          ),
        ],
      ],
    );
  }
}
