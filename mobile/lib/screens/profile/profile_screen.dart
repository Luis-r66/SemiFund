import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/semillero_membership.dart';
import '../../models/user.dart';
import '../../providers/session_provider.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/buttons.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/section_label.dart';
import '../../widgets/semillero_switcher_sheet.dart';
import '../../widgets/status_badge.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final SessionProvider session = context.read<SessionProvider>();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Seguro que quieres salir de tu cuenta?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await session.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final SessionProvider session = context.watch<SessionProvider>();
    final UserModel? user = session.user;
    final String name = user?.nombre ?? '';
    final String email = user?.email ?? '';
    final SemilleroMembership? active = session.activeSemillero;
    final bool isStudent = user?.tipoUsuario == UserType.estudiante;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AppTopBar(
              title: 'Perfil',
              onBack: () {
                if (GoRouter.of(context).canPop()) {
                  context.pop();
                } else {
                  context.go(
                    session.hasActiveSemillero ? '/home' : '/semilleros',
                  );
                }
              },
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: <Widget>[
                  const SizedBox(height: 8),
                  Center(
                    child: MemberAvatar(
                      name: name,
                      initialsOverride: session.user?.initials,
                      size: 76,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.h2,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.small.copyWith(color: AppColors.ink2),
                  ),
                  const SizedBox(height: 28),
                  const SectionLabel('Cuenta'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: <Widget>[
                        _InfoRow(label: 'Nombre', value: name),
                        const Divider(),
                        _InfoRow(label: 'Correo', value: email),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SectionLabel('Datos académicos'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: <Widget>[
                        _InfoRow(
                          label: 'Tipo',
                          value: user?.tipoUsuario?.label ?? 'Sin completar',
                        ),
                        const Divider(),
                        _InfoRow(
                          label: user?.tipoUsuario == UserType.profesor
                              ? 'Área'
                              : 'Carrera',
                          value: user?.programa ?? 'Sin completar',
                        ),
                        if (isStudent) ...<Widget>[
                          const Divider(),
                          _InfoRow(
                            label: 'Semestre',
                            value: user?.semestre == null
                                ? 'Sin completar'
                                : '${user!.semestre}°',
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SecondaryButton(
                    label: 'Editar datos académicos',
                    onPressed: () => context.push('/profile/academic'),
                  ),
                  const SizedBox(height: 24),
                  const SectionLabel('Membresía activa'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: active == null
                        ? Text(
                            'No has entrado a ningún semillero.',
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.ink3,
                            ),
                          )
                        : Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      active.nombre,
                                      style: AppTextStyles.bodySemibold,
                                    ),
                                    const SizedBox(height: 7),
                                    StatusBadge.membership(active),
                                  ],
                                ),
                              ),
                              Text(
                                '${active.miembros} ${active.miembros == 1 ? 'integrante' : 'integrantes'}',
                                style: AppTextStyles.small.copyWith(
                                  color: AppColors.ink2,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 24),
                  SecondaryButton(
                    label: 'Cambiar contraseña',
                    onPressed: () => context.push('/change-password'),
                  ),
                  const SizedBox(height: 10),
                  SecondaryButton(
                    label: 'Cambiar semillero',
                    onPressed: () => showSemilleroSwitcher(context, session),
                  ),
                  const SizedBox(height: 10),
                  DangerButton(
                    label: 'Cerrar sesión',
                    onPressed: session.isBusy
                        ? null
                        : () => _confirmLogout(context),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: AppTextStyles.small.copyWith(color: AppColors.ink2),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.smallSemibold,
            ),
          ),
        ],
      ),
    );
  }
}
