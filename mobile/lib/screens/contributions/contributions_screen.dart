import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/contribution.dart';
import '../../providers/contributions_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/management_service.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/form_controls.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/section_label.dart';
import '../../widgets/status_badge.dart';

class ContributionsScreen extends StatefulWidget {
  const ContributionsScreen({super.key});

  @override
  State<ContributionsScreen> createState() => _ContributionsScreenState();
}

enum _Tab { todos, pendiente, vencido, reportado }

class _ContributionsScreenState extends State<ContributionsScreen> {
  _Tab _tab = _Tab.todos;
  bool _exporting = false;

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
      case _Tab.reportado:
        return ContributionStatus.reportado;
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
      case _Tab.reportado:
        return 'Reportado';
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

  Future<void> _report(Contribution contribution) async {
    final ContributionsProvider provider = context
        .read<ContributionsProvider>();
    final TextEditingController reference = TextEditingController();
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Reportar pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'El tesorero revisará el reporte antes de marcarlo como pagado.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reference,
              decoration: const InputDecoration(
                labelText: 'Referencia (opcional)',
                hintText: 'Número de transacción',
              ),
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(reference.text),
            child: const Text('Reportar'),
          ),
        ],
      ),
    );
    reference.dispose();
    if (result == null) return;
    try {
      await provider.report(contribution, referencia: result);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _reject(Contribution contribution) async {
    final ContributionsProvider provider = context
        .read<ContributionsProvider>();
    final TextEditingController reason = TextEditingController();
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Rechazar reporte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('El aporte volverá a quedar pendiente.'),
            const SizedBox(height: 12),
            TextField(
              controller: reason,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
                hintText: 'Ej. Comprobante ilegible',
              ),
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(reason.text),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    reason.dispose();
    if (result == null) return;
    try {
      await provider.reject(contribution, motivo: result);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final CsvDownload file = await context
          .read<ContributionsProvider>()
          .exportCsv();
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[
            XFile.fromData(
              file.bytes,
              mimeType: 'text/csv',
              name: file.filename,
            ),
          ],
          downloadFallbackEnabled: true,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _exporting = false);
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
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                          tooltip: 'Exportar CSV',
                          onPressed: _exporting ? null : _export,
                          icon: _exporting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.download_outlined),
                        ),
                        RoundAddButton(
                          onPressed: () => context.push('/contributions/new'),
                        ),
                      ],
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
                            canReport: !isTreasurer && item.canReport,
                            canReject:
                                isTreasurer &&
                                item.estado == ContributionStatus.reportado,
                            onPay: () => _pay(item),
                            onReport: () => _report(item),
                            onReject: () => _reject(item),
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
    required this.canReport,
    required this.canReject,
    required this.onPay,
    required this.onReport,
    required this.onReject,
  });

  final String name;
  final Contribution contribution;
  final bool canPay;
  final bool canReport;
  final bool canReject;
  final VoidCallback onPay;
  final VoidCallback onReport;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final bool hasActions = canPay || canReport || canReject;
    return Material(
      color: AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Row(
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
            if (hasActions) ...<Widget>[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  if (canReject)
                    TextButton(
                      onPressed: onReject,
                      child: const Text('Rechazar'),
                    ),
                  if (canReport)
                    TextButton(
                      onPressed: onReport,
                      child: const Text('Reportar pago'),
                    ),
                  if (canPay)
                    TextButton(
                      onPressed: onPay,
                      child: const Text('Registrar pago'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
