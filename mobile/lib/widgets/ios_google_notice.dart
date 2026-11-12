import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// Aviso para iPhone. Dentro de la app instalada en la pantalla de inicio,
/// iOS puede no devolver el control después del selector de cuentas de Google.
/// En Android y en escritorio no ocupa espacio.
class IosGoogleNotice extends StatelessWidget {
  const IosGoogleNotice({super.key});

  static bool get visible =>
      kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(LucideIcons.info, size: 14, color: AppColors.ink3),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Si instalaste SemiFund en la pantalla de inicio, usa correo y '
              'contraseña: el inicio con Google puede no volver a la app.',
              style: AppTextStyles.small.copyWith(color: AppColors.ink3),
            ),
          ),
        ],
      ),
    );
  }
}
