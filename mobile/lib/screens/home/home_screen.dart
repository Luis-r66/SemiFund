import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/balance.dart';
import '../../models/semillero_membership.dart';
import '../../providers/home_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/section_label.dart';
import '../../widgets/semillero_switcher_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _loadedSemilleroId;

  /// Abre un módulo y refresca el saldo al volver (puede haber cambiado).
  Future<void> _open(String path) async {
    await context.push(path);
    if (!mounted) return;
    context.read<HomeProvider>().refresh();
  }

  void _ensureLoaded(SemilleroMembership? active) {
    if (active == null) return;
    if (_loadedSemilleroId == active.semilleroId) return;
    _loadedSemilleroId = active.semilleroId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HomeProvider>().load(active.semilleroId, force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final SessionProvider session = context.watch<SessionProvider>();
    final HomeProvider home = context.watch<HomeProvider>();
    final SemilleroMembership? active = session.activeSemillero;
    final String name = session.user?.nombre ?? '';

    _ensureLoaded(active);

    if (active == null) {
      return const Scaffold(
        backgroundColor: AppColors.paper,
        body: Center(child: LoadingView()),
      );
    }

    final HomeSnapshot? snapshot = home.snapshot;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'SemiFund · ${session.isTesorero ? 'Tesorero' : 'Integrante'}',
                          style: AppTextStyles.tinyMedium.copyWith(
                            color: AppColors.ink3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        InkWell(
                          onTap: () => showSemilleroSwitcher(context, session),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Flexible(
                                  child: Text(
                                    active.nombre,
                                    style: AppTextStyles.h3,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Icon(
                                  LucideIcons.chevronDown,
                                  size: 18,
                                  color: AppColors.ink2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => context.push('/profile'),
                    customBorder: const CircleBorder(),
                    child: MemberAvatar(name: name, size: 40, light: true),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: home.refresh,
                color: AppColors.ink,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  children: <Widget>[
                    if (home.error != null) ...<Widget>[
                      ErrorBanner(message: home.error!, onRetry: home.refresh),
                      const SizedBox(height: 14),
                    ],
                    if (snapshot == null)
                      SizedBox(
                        height: 380,
                        child: LoadingView(
                          message: home.loading
                              ? 'Cargando información del semillero...'
                              : 'Desliza hacia abajo para actualizar.',
                        ),
                      )
                    else ...<Widget>[
                      BalanceCard(
                        saldo: snapshot.balance.saldoDisponible,
                        updatedAt: snapshot.updatedAt,
                      ),
                      const SizedBox(height: 12),
                      _TotalsCard(balance: snapshot.balance),
                      const SizedBox(height: 28),
                      const SectionLabel('Gestionar'),
                      _ManageTile(
                        icon: LucideIcons.users,
                        title: 'Integrantes',
                        subtitle:
                            '${snapshot.activeMembers} ${snapshot.activeMembers == 1 ? 'activo' : 'activos'}',
                        onTap: () => _open('/members'),
                      ),
                      const SizedBox(height: 10),
                      _ManageTile(
                        icon: LucideIcons.wallet,
                        title: 'Aportes',
                        subtitle: '${snapshot.pendingContributions} por cobrar',
                        onTap: () => _open('/contributions'),
                      ),
                      const SizedBox(height: 10),
                      _ManageTile(
                        icon: LucideIcons.receipt,
                        title: 'Gastos',
                        subtitle: '${snapshot.expensesCount} registrados',
                        onTap: () => _open('/expenses'),
                      ),
                      if (session.isTesorero) ...<Widget>[
                        const SizedBox(height: 28),
                        const SectionLabel('Administrar semillero'),
                        _ManageTile(
                          icon: LucideIcons.userPlus,
                          title: 'Cuentas',
                          subtitle: 'Solicitudes y roles',
                          onTap: () => _open('/accounts'),
                        ),
                        const SizedBox(height: 10),
                        _ManageTile(
                          icon: LucideIcons.shieldCheck,
                          title: 'Invitar integrantes',
                          subtitle: 'Comparte el código del semillero',
                          onTap: () => _open('/invite'),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.balance});

  final Balance balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Total aportado',
                  style: AppTextStyles.smallMedium.copyWith(
                    color: AppColors.ink2,
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatCop(balance.totalAportado),
                    style: AppTextStyles.moneyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                'Total gastado',
                style: AppTextStyles.tiny.copyWith(color: AppColors.ink3),
              ),
              const SizedBox(height: 6),
              Text(
                formatCop(balance.totalGastado),
                style: AppTextStyles.moneyTiny.copyWith(color: AppColors.ink2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManageTile extends StatelessWidget {
  const _ManageTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

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
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.mist,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 21, color: AppColors.ink),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: AppTextStyles.h4),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
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
