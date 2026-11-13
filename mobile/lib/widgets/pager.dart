import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/layout/app_layout.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// Controles de paginación compartidos.
///
/// - Escritorio: página anterior / siguiente con el indicador "Página X de Y".
/// - Móvil: botón "Cargar más" que acumula registros.
class Pager extends StatelessWidget {
  const Pager({
    super.key,
    required this.page,
    required this.pages,
    required this.loading,
    required this.onPage,
    required this.onLoadMore,
  });

  final int page;
  final int pages;
  final bool loading;
  final ValueChanged<int> onPage;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (pages <= 1) return const SizedBox.shrink();

    if (!AppLayout.isDesktop(context)) {
      if (page >= pages) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: SizedBox(
          height: 46,
          width: double.infinity,
          child: OutlinedButton(
            onPressed: loading ? null : onLoadMore,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.line),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: AppTextStyles.smallSemibold,
            ),
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Cargar más'),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Text(
            'Página $page de $pages',
            style: AppTextStyles.small.copyWith(color: AppColors.ink2),
          ),
          const SizedBox(width: 10),
          _PageButton(
            icon: LucideIcons.chevronLeft,
            tooltip: 'Página anterior',
            onPressed: page > 1 && !loading ? () => onPage(page - 1) : null,
          ),
          const SizedBox(width: 4),
          _PageButton(
            icon: LucideIcons.chevronRight,
            tooltip: 'Página siguiente',
            onPressed: page < pages && !loading ? () => onPage(page + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: AppColors.ink),
      style: IconButton.styleFrom(
        minimumSize: const Size(36, 36),
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
