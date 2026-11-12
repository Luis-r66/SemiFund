import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../core/layout/app_layout.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/semillero_membership.dart';
import '../providers/session_provider.dart';
import 'app_logo.dart';
import 'member_avatar.dart';
import 'section_label.dart';
import 'semillero_switcher_sheet.dart';

/// Caparazón de la web de escritorio: barra lateral fija y contenido.
///
/// En pantallas menores a [AppLayout.desktopMin] devuelve el contenido tal
/// cual, así la app móvil y la PWA de iPhone no cambian.
class DesktopShell extends StatelessWidget {
  const DesktopShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!AppLayout.isDesktop(context)) return child;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Row(
          children: <Widget>[
            _DesktopSidebar(location: location),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({required this.location});

  final String location;

  static const double _width = 248;
  static const double _horizontal = 14;

  bool _isActive(String path) {
    if (path == '/home') return location == '/home';
    return location == path || location.startsWith('$path/');
  }

  @override
  Widget build(BuildContext context) {
    final SessionProvider session = context.watch<SessionProvider>();
    final SemilleroMembership? active = session.activeSemillero;
    final String name = session.user?.nombre ?? '';

    return Container(
      key: const ValueKey<String>('desktop-sidebar'),
      width: _width,
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(right: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: Row(
              children: <Widget>[
                const AppLogo(size: 34, showLabel: false),
                const SizedBox(width: 10),
                Text('SemiFund', style: AppTextStyles.h4),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _horizontal),
            child: _SemilleroButton(session: session, active: active),
          ),
          const SizedBox(height: 20),
          if (active != null)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: _horizontal),
                children: <Widget>[
                  _NavItem(
                    icon: LucideIcons.house,
                    label: 'Inicio',
                    selected: _isActive('/home'),
                    onTap: () => context.go('/home'),
                  ),
                  _NavItem(
                    icon: LucideIcons.users,
                    label: 'Integrantes',
                    selected: _isActive('/members'),
                    onTap: () => context.go('/members'),
                  ),
                  _NavItem(
                    icon: LucideIcons.wallet,
                    label: 'Aportes',
                    selected: _isActive('/contributions'),
                    onTap: () => context.go('/contributions'),
                  ),
                  _NavItem(
                    icon: LucideIcons.receipt,
                    label: 'Gastos',
                    selected: _isActive('/expenses'),
                    onTap: () => context.go('/expenses'),
                  ),
                  if (session.isTesorero) ...<Widget>[
                    const SizedBox(height: 22),
                    const SectionLabel('Administración'),
                    _NavItem(
                      icon: LucideIcons.shieldCheck,
                      label: 'Cuentas',
                      selected: _isActive('/accounts'),
                      onTap: () => context.go('/accounts'),
                    ),
                    _NavItem(
                      icon: LucideIcons.userPlus,
                      label: 'Invitar integrantes',
                      selected: _isActive('/invite'),
                      onTap: () => context.go('/invite'),
                    ),
                    _NavItem(
                      icon: LucideIcons.history,
                      label: 'Actividad',
                      selected: _isActive('/activity'),
                      onTap: () => context.go('/activity'),
                    ),
                  ],
                ],
              ),
            )
          else
            const Spacer(),
          const Divider(height: 1, color: AppColors.line),
          _UserButton(
            name: name,
            initials: session.user?.initials,
            onTap: () => context.go('/profile'),
          ),
        ],
      ),
    );
  }
}

class _SemilleroButton extends StatelessWidget {
  const _SemilleroButton({required this.session, required this.active});

  final SessionProvider session;
  final SemilleroMembership? active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.mist,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showSemilleroSwitcher(context, session),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'SEMILLERO',
                      style: AppTextStyles.label.copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      active?.nombre ?? 'Elegir semillero',
                      style: AppTextStyles.smallSemibold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (active != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        session.isTesorero ? 'Tesorero' : 'Integrante',
                        style: AppTextStyles.tiny.copyWith(
                          color: AppColors.ink3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                LucideIcons.chevronDown,
                size: 17,
                color: AppColors.ink2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected ? AppColors.mist : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: <Widget>[
                Icon(
                  icon,
                  size: 18,
                  color: selected ? AppColors.ink : AppColors.ink2,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.smallMedium.copyWith(
                      color: selected ? AppColors.ink : AppColors.ink2,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserButton extends StatelessWidget {
  const _UserButton({
    required this.name,
    required this.initials,
    required this.onTap,
  });

  final String name;
  final String? initials;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 13, 14, 13),
          child: Row(
            children: <Widget>[
              MemberAvatar(
                name: name,
                initialsOverride: initials,
                size: 34,
                light: true,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name.isEmpty ? 'Mi perfil' : name,
                      style: AppTextStyles.smallSemibold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Ver perfil',
                      style: AppTextStyles.tiny.copyWith(color: AppColors.ink3),
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: AppColors.ink3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
