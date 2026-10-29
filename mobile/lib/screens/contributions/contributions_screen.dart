import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/contribution.dart';
import '../../providers/contributions_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/form_controls.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/section_label.dart';
import '../../widgets/status_badge.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

class ContributionsScreen extends StatefulWidget {
  const ContributionsScreen({super.key});

  @override
  State<ContributionsScreen> createState() => _ContributionsScreenState();
}

/// Filtro de la pestaña: null = Todos.
enum _Tab { todos, pendiente, vencido }

class _ContributionsScreenState extends State<ContributionsScreen> {
  _Tab _tab = _Tab.todos;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ContributionsProvider>().load();
    });
  }

  ContributionStatus? _statusFor(_Tab tab) {
    switch (tab) {
      case _Tab.todos:
        return null;
      case _Tab.pendiente:
        return ContributionStatus.pendiente;
      case _Tab.vencido:
        return ContributionStatus.vencido;
    }
  }

  String _labelFor(_Tab tab) {
    switch (tab) {
      case _Tab.todos:
        return 'Todos';
      case _Tab.pendiente:
        return 'Pendiente';
      case _Tab.vencido:
        return 'Vencido';
    }
  }

  void _select(_Tab tab) {
    setState(() => _tab = tab);
    context.read<ContributionsProvider>().load(status: _statusFor(tab));
  }

  Future<void> _pay(Contribution contribution) async {
    final ContributionsProvider provider = context
        .read<ContributionsProvider>();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Registrar pago'),
        content: Text(
          '¿Confirmas el pago de ${formatCop(contribution.monto)} de '
          '${provider.memberName(contribution.integranteId)}?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Registrar pago'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await provider.pay(contribution);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ContributionsProvider contributions = context
        .watch<ContributionsProvider>();
    final bool isTreasurer = context.watch<SessionProvider>().isTesorero;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AppTopBar(
              title: 'Aportes',
              onBack: () => context.pop(),
              trailing: isTreasurer
                  ? RoundAddButton(
                      onPressed: () => context.push('/contributions/new'),
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: SegmentedTabs<_Tab>(
                options: _Tab.values,
                selected: _tab,
                labelOf: _labelFor,
                onChanged: _select,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: contributions.refresh,
                color: AppColors.ink,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: <Widget>[
                    if (contributions.error != null) ...<Widget>[
                      ErrorBanner(
                        message: contributions.error!,
                        onRetry: contributions.refresh,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (contributions.loading && contributions.items.isEmpty)
                      const SizedBox(height: 360, child: LoadingView())
                    else if (contributions.items.isEmpty)
                      const EmptyState(
                        icon: LucideIcons.wallet,
                        title: 'Sin aportes',
                        message: 'No hay aportes para este filtro.',
                      )
                    else ...<Widget>[
                      SectionLabel(
                        '${contributions.items.length} ${contributions.items.length == 1 ? 'registro' : 'registros'}',
                      ),
                      for (final Contribution item in contributions.items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ContributionTile(
                            name: contributions.memberName(item.integranteId),
                            contribution: item,
                            canPay: isTreasurer && !item.isPaid,
                            onPay: () => _pay(item),
                          ),
                        ),
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

class _ContributionTile extends StatelessWidget {
  const _ContributionTile({
    required this.name,
    required this.contribution,
    required this.canPay,
    required this.onPay,
  });

  final String name;
  final Contribution contribution;
  final bool canPay;
  final VoidCallback onPay;

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
        onTap: canPay ? onPay : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      style: AppTextStyles.bodySemibold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatMonth(contribution.mes),
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.ink2,
                      ),
                    ),
                    if (contribution.concepto.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        contribution.concepto,
                        style: AppTextStyles.tiny.copyWith(
                          color: AppColors.ink3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    formatCop(contribution.monto),
                    style: AppTextStyles.moneySmall,
                  ),
                  const SizedBox(height: 6),
                  StatusBadge.contribution(contribution),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
