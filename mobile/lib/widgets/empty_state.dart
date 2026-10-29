import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.mist,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26, color: AppColors.ink3),
          ),
          const SizedBox(height: 18),
          Text(title, textAlign: TextAlign.center, style: AppTextStyles.h4),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.small.copyWith(color: AppColors.ink2),
          ),
          if (action != null) ...<Widget>[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}
