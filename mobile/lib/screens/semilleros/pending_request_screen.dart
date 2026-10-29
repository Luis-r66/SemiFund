import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/semillero_membership.dart';
import '../../providers/session_provider.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/buttons.dart';
import '../../widgets/status_badge.dart';

class PendingRequestScreen extends StatelessWidget {
  const PendingRequestScreen({super.key, this.membership});

  final SemilleroMembership? membership;

  SemilleroMembership? _resolve(SessionProvider session) {
    if (membership != null) return membership;
    for (final SemilleroMembership item in session.semilleros) {
      if (item.estado == MembershipStatus.pendiente) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final SessionProvider session = context.watch<SessionProvider>();
    final SemilleroMembership? item = _resolve(session);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AppTopBar(title: '', onBack: () => context.go('/semilleros')),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 42),
                    Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: AppColors.warnSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.clock,
                        size: 28,
                        color: AppColors.warn,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Solicitud pendiente',
                      style: AppTextStyles.h2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Solicitud enviada. El tesorero debe aprobar tu cuenta.',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.ink2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    if (item != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          border: Border.all(color: AppColors.line),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Semillero',
                              style: AppTextStyles.tiny.copyWith(
                                color: AppColors.ink3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.nombre,
                              style: AppTextStyles.bodySemibold,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: <Widget>[
                                const StatusBadge(
                                  label: 'Pendiente',
                                  tone: BadgeTone.warn,
                                ),
                                Text(
                                  'Te avisaremos al ser aprobado',
                                  style: AppTextStyles.tiny.copyWith(
                                    color: AppColors.ink2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: PrimaryButton(
                label: 'Volver al inicio',
                onPressed: () => context.go('/semilleros'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
