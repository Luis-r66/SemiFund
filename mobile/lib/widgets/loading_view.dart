import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          if (message != null) ...<Widget>[
            const SizedBox(height: 14),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTextStyles.small.copyWith(color: AppColors.ink2),
            ),
          ],
        ],
      ),
    );
  }
}
