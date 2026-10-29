import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.badSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33C62F2F)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              LucideIcons.alertCircle,
              size: 17,
              color: AppColors.bad,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.smallMedium.copyWith(color: AppColors.bad),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.bad,
                minimumSize: const Size(0, 30),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Reintentar'),
            ),
        ],
      ),
    );
  }
}
