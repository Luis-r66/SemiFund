import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/contribution.dart';
import '../models/semillero_membership.dart';

enum BadgeTone { ok, warn, bad, muted }

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.tone});

  final String label;
  final BadgeTone tone;

  factory StatusBadge.membership(SemilleroMembership membership) {
    switch (membership.estado) {
      case MembershipStatus.activo:
        return StatusBadge(
          label: membership.esTesorero ? 'Tesorero' : 'Integrante',
          tone: membership.esTesorero ? BadgeTone.ok : BadgeTone.muted,
        );
      case MembershipStatus.pendiente:
        return const StatusBadge(label: 'Pendiente', tone: BadgeTone.warn);
      case MembershipStatus.rechazado:
      case MembershipStatus.inactivo:
        return StatusBadge(label: membership.estado.label, tone: BadgeTone.bad);
      case MembershipStatus.desconocido:
        return const StatusBadge(label: 'Sin estado', tone: BadgeTone.muted);
    }
  }

  factory StatusBadge.contribution(Contribution contribution) {
    switch (contribution.estado) {
      case ContributionStatus.pendiente:
        return const StatusBadge(label: 'Pendiente', tone: BadgeTone.warn);
      case ContributionStatus.pagado:
        return const StatusBadge(label: 'Pagado', tone: BadgeTone.ok);
      case ContributionStatus.vencido:
        return const StatusBadge(label: 'Vencido', tone: BadgeTone.bad);
      case ContributionStatus.reportado:
        return const StatusBadge(label: 'Reportado', tone: BadgeTone.warn);
    }
  }

  factory StatusBadge.active({required bool active}) {
    return active
        ? const StatusBadge(label: 'Activo', tone: BadgeTone.ok)
        : const StatusBadge(label: 'Inactivo', tone: BadgeTone.muted);
  }

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) = switch (tone) {
      BadgeTone.ok => (AppColors.okSoft, AppColors.ok),
      BadgeTone.warn => (AppColors.warnSoft, AppColors.warn),
      BadgeTone.bad => (AppColors.badSoft, AppColors.bad),
      BadgeTone.muted => (AppColors.mist, AppColors.ink2),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.tinySemibold.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
