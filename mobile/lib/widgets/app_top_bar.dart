import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key, required this.title, this.onBack, this.trailing});

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: <Widget>[
          if (onBack != null)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: IconButton(
                onPressed: onBack,
                tooltip: 'Atrás',
                icon: const Icon(LucideIcons.arrowLeft, size: 20),
                color: AppColors.ink,
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                padding: EdgeInsets.zero,
              ),
            )
          else
            const SizedBox(width: 20),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.h3,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null)
            Padding(padding: const EdgeInsets.only(right: 16), child: trailing!)
          else
            const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class RoundAddButton extends StatelessWidget {
  const RoundAddButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Agregar',
  });

  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.paper,
        ),
        icon: const Icon(LucideIcons.plus, size: 20),
      ),
    );
  }
}
