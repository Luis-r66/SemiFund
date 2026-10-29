import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/semillero_membership.dart';
import 'status_badge.dart';

class SemilleroCard extends StatelessWidget {
  const SemilleroCard({
    super.key,
    required this.membership,
    required this.onTap,
  });

  final SemilleroMembership membership;
  final VoidCallback onTap;

  String get _secondaryText {
    switch (membership.estado) {
      case MembershipStatus.activo:
        final String suffix = membership.miembros == 1
            ? 'integrante'
            : 'integrantes';
        return '${membership.miembros} $suffix';
      case MembershipStatus.pendiente:
        return 'Esperando aprobación';
      case MembershipStatus.rechazado:
        return 'Solicitud rechazada';
      case MembershipStatus.inactivo:
        return 'Ya no participas en este semillero';
      case MembershipStatus.desconocido:
        return 'Estado no disponible';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      membership.nombre,
                      style: AppTextStyles.h4,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        StatusBadge.membership(membership),
                        Text(
                          _secondaryText,
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.ink2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                LucideIcons.chevronRight,
                size: 19,
                color: AppColors.ink3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
