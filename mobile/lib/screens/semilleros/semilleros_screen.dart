import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/semillero_membership.dart';
import '../../providers/session_provider.dart';
import '../../widgets/buttons.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/section_label.dart';
import '../../widgets/semillero_card.dart';

class SemillerosScreen extends StatelessWidget {
  const SemillerosScreen({super.key});

  Future<void> _openMembership(
    BuildContext context,
    SessionProvider session,
    SemilleroMembership membership,
  ) async {
    if (membership.isActive) {
      try {
        await session.selectSemillero(membership);
        if (context.mounted) context.go('/home');
      } on ApiException catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error.message)));
        }
      }
      return;
    }

    if (membership.estado == MembershipStatus.pendiente) {
      context.push('/semilleros/pending', extra: membership);
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        final String message = switch (membership.estado) {
          MembershipStatus.rechazado =>
            'Tu solicitud para este semillero fue rechazada.',
          MembershipStatus.inactivo => 'Ya no participas en este semillero.',
          _ => 'Este semillero no está disponible para ingresar.',
        };
        return AlertDialog(
          title: Text(membership.nombre),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cerrar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.push('/semilleros/join');
              },
              child: const Text('Unirme con código'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final SessionProvider session = context.watch<SessionProvider>();
    final List<SemilleroMembership> items = session.semilleros;
    final String name = session.user?.nombre ?? '';

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Hola, ${firstName(name)}',
                          style: AppTextStyles.tinyMedium.copyWith(
                            color: AppColors.ink3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text('Mis semilleros', style: AppTextStyles.h1),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push('/profile'),
                    customBorder: const CircleBorder(),
                    child: MemberAvatar(name: name, size: 40, light: true),
                  ),
                ],
              ),
            ),
            if (session.notice != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: ErrorBanner(
                  message: session.notice!,
                  onRetry: session.refreshSemilleros,
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: session.refreshSemilleros,
                color: AppColors.ink,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  children: <Widget>[
                    if (items.isNotEmpty) ...<Widget>[
                      SectionLabel(
                        '${items.length} ${items.length == 1 ? 'semillero' : 'semilleros'}',
                      ),
                      ...items.map(
                        (SemilleroMembership membership) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SemilleroCard(
                            membership: membership,
                            onTap: () =>
                                _openMembership(context, session, membership),
                          ),
                        ),
                      ),
                    ] else
                      EmptyState(
                        icon: LucideIcons.building2,
                        title: 'Aún no tienes semilleros',
                        message: 'Crea uno nuevo o únete con el código que te compartió el tesorero.',
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Column(
                children: <Widget>[
                  PrimaryButton(
                    label: 'Crear semillero',
                    onPressed: () => context.push('/semilleros/create'),
                  ),
                  const SizedBox(height: 10),
                  SecondaryButton(
                    label: 'Unirme con código',
                    onPressed: () => context.push('/semilleros/join'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
