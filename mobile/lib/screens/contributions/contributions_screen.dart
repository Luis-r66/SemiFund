import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/abono.dart';
import '../../models/contribution.dart';
import '../../providers/contributions_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/management_service.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/buttons.dart';
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

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _pay(Contribution contribution) async {
    final ContributionsProvider provider = context
        .read<ContributionsProvider>();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Pago total'),
        content: Text(
          '¿Confirmas el pago de ${formatCop(contribution.saldoPendiente)} de '
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
    await _guard(() => provider.pay(contribution));
  }

  Future<void> _reportAbono(Contribution contribution) async {
    final ContributionsProvider provider = context
        .read<ContributionsProvider>();
    final _InputResult? result = await _ask(
      _InputDialog(
        title: 'Reportar pago',
        description: 'Puedes reportar el total o una parte. El tesorero revisará el reporte antes de aprobarlo.',
        confirmLabel: 'Reportar',
        saldo: contribution.saldoPendiente,
        fieldLabel: 'Referencia (opcional)',
        fieldHint: 'Número de transacción',
      ),
    );
    if (result == null) return;
    await _guard(
      () => provider.addPayment(
        contribution,
        monto: result.monto,
        referencia: result.texto,
      ),
    );
  }

  Future<void> _registerAbono(Contribution contribution) async {
    final ContributionsProvider provider = context
        .read<ContributionsProvider>();
    final _InputResult? result = await _ask(
      _InputDialog(
        title: 'Registrar abono',
        description: 'El dinero queda aprobado de inmediato. Úsalo para efectivo o consignaciones ya recibidas.',
        confirmLabel: 'Registrar',
        saldo: contribution.saldoPendiente,
        fieldLabel: 'Referencia (opcional)',
        fieldHint: 'Ej. Consignación Bancolombia',
      ),
    );
    if (result == null) return;
    await _guard(
      () => provider.addPayment(
        contribution,
        monto: result.monto,
        referencia: result.texto,
      ),
    );
  }

  Future<void> _approve(Contribution contribution, Abono abono) async {
    final ContributionsProvider provider = context
        .read<ContributionsProvider>();
    await _guard(() => provider.approvePayment(contribution, abono));
  }

  Future<void> _rejectAbono(Contribution contribution, Abono abono) async {
    final ContributionsProvider provider = context
        .read<ContributionsProvider>();
    final _InputResult? result = await _ask(
      _InputDialog(
        title: 'Rechazar abono',
        description:
            'El abono no suma al cobrado. La cuota sigue con el mismo saldo.',
        confirmLabel: 'Rechazar',
        fieldLabel: 'Motivo (opcional)',
        fieldHint: 'Ej. Comprobante ilegible',
      ),
    );
    if (result == null) return;
    await _guard(
      () => provider.rejectPayment(contribution, abono, motivo: result.texto),
    );
  }

  Future<void> _voidAbono(Contribution contribution, Abono abono) async {
    final ContributionsProvider provider = context
        .read<ContributionsProvider>();
    final _InputResult? result = await _ask(
      _InputDialog(
        title: 'Anular abono',
        description: 'Se descontará de lo cobrado y la cuota volverá a quedar con saldo pendiente.',
        confirmLabel: 'Anular',
        fieldLabel: 'Motivo (opcional)',
        fieldHint: 'Ej. Aprobado por error',
      ),
    );
    if (result == null) return;
    await _guard(
      () => provider.voidPayment(contribution, abono, motivo: result.texto),
    );
  }

  Future<_InputResult?> _ask(_InputDialog dialog) {
    return showDialog<_InputResult>(
      context: context,
      builder: (BuildContext dialogContext) => dialog,
    );
  }

  Future<void> _openDetail(Contribution item) async {
    final ContributionsProvider provider = context
        .read<ContributionsProvider>();
    final bool isTreasurer = context.read<SessionProvider>().isTesorero;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => _DetailSheet(
        name: provider.memberName(item.integranteId),
        contribution: item,
        isTreasurer: isTreasurer,
        canReport: !isTreasurer && item.canReport,
        canRegister: isTreasurer && !item.isPaid && !item.hasAbonoReportado,
        onReport: () {
          Navigator.of(sheetContext).pop();
          _reportAbono(item);
        },
        onRegister: () {
          Navigator.of(sheetContext).pop();
          _registerAbono(item);
        },
        onApprove: (Abono abono) {
          Navigator.of(sheetContext).pop();
          _approve(item, abono);
        },
        onReject: (Abono abono) {
          Navigator.of(sheetContext).pop();
          _rejectAbono(item, abono);
        },
        onVoid: (Abono abono) {
          Navigator.of(sheetContext).pop();
          _voidAbono(item, abono);
        },
      ),
    );
  }

  Future<void> _openBulk() async {
    final ContributionsProvider provider = context
        .read<ContributionsProvider>();
    final _BulkInput? input = await showDialog<_BulkInput>(
      context: context,
      builder: (BuildContext dialogContext) => const _BulkDialog(),
    );
    if (input == null) return;
    try {
      final BulkContributionResult result = await provider.createBulk(
        mes: input.mes,
        monto: input.monto,
        concepto: input.concepto,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.creadas} ${result.creadas == 1 ? 'cuota creada' : 'cuotas creadas'}'
            '${result.omitidas > 0 ? ' · ${result.omitidas} omitidas (ya existían o están inactivas)' : ''}',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _export(
    Future<CsvDownload> Function(ContributionsProvider provider) fetch,
  ) async {
    setState(() => _exporting = true);
    try {
      final CsvDownload file = await fetch(
        context.read<ContributionsProvider>(),
      );
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
                          tooltip: 'Cuotas del mes',
                          onPressed: _openBulk,
                          icon: const Icon(LucideIcons.calendarPlus, size: 20),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Exportar',
                          enabled: !_exporting,
                          onSelected: (String format) => _export(
                            (ContributionsProvider provider) => format == 'xlsx'
                                ? provider.exportExcel()
                                : provider.exportCsv(),
                          ),
                          itemBuilder: (BuildContext context) =>
                              const <PopupMenuEntry<String>>[
                                PopupMenuItem<String>(
                                  value: 'xlsx',
                                  child: Text('Excel (libro completo)'),
                                ),
                                PopupMenuItem<String>(
                                  value: 'csv',
                                  child: Text('CSV (movimientos)'),
                                ),
                              ],
                          icon: _exporting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  LucideIcons.fileSpreadsheet,
                                  size: 20,
                                ),
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
                            canRegister:
                                isTreasurer &&
                                !item.isPaid &&
                                !item.hasAbonoReportado,
                            canPayTotal:
                                isTreasurer &&
                                !item.isPaid &&
                                !item.hasAbonoReportado,
                            canReport: !isTreasurer && item.canReport,
                            canReview: isTreasurer && item.hasAbonoReportado,
                            onDetail: () => _openDetail(item),
                            onRegister: () => _registerAbono(item),
                            onPayTotal: () => _pay(item),
                            onReport: () => _reportAbono(item),
                            onReview: () => _openDetail(item),
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

class _BulkInput {
  const _BulkInput({
    required this.mes,
    required this.monto,
    required this.concepto,
  });

  final String mes;
  final double monto;
  final String concepto;
}

class _BulkDialog extends StatefulWidget {
  const _BulkDialog();

  @override
  State<_BulkDialog> createState() => _BulkDialogState();
}

class _BulkDialogState extends State<_BulkDialog> {
  final List<String> _months = monthOptions(DateTime.now());
  late String? _mes = currentMonth(DateTime.now());
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _concept = TextEditingController(
    text: 'Cuota mensual',
  );
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _concept.dispose();
    super.dispose();
  }

  void _confirm() {
    final double monto = parseMoney(_amount.text);
    if (_mes == null) {
      setState(() => _error = 'Selecciona el mes.');
      return;
    }
    if (monto <= 0) {
      setState(() => _error = 'Ingresa un monto mayor a 0.');
      return;
    }
    if (_concept.text.trim().isEmpty) {
      setState(() => _error = 'Escribe un concepto.');
      return;
    }
    Navigator.of(
      context,
    ).pop(_BulkInput(mes: _mes!, monto: monto, concepto: _concept.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cuotas del mes'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Se crea una cuota para cada integrante activo que aún no tenga una en ese mes.',
            ),
            const SizedBox(height: 12),
            SelectField<String>(
              value: _mes,
              items: _months,
              labelOf: formatMonth,
              hintText: 'Selecciona el mes',
              onChanged: (String? value) => setState(() => _mes = value),
            ),
            const SizedBox(height: 12),
            MoneyField(
              controller: _amount,
              invalid: _error != null && parseMoney(_amount.text) <= 0,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _concept,
              decoration: const InputDecoration(labelText: 'Concepto'),
              onChanged: (_) => setState(() => _error = null),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: AppTextStyles.small.copyWith(color: AppColors.bad),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _confirm, child: const Text('Crear cuotas')),
      ],
    );
  }
}

class _InputResult {
  const _InputResult({this.monto, this.texto = ''});

  final double? monto;
  final String texto;
}

class _InputDialog extends StatefulWidget {
  const _InputDialog({
    required this.title,
    required this.description,
    required this.confirmLabel,
    this.saldo,
    this.fieldLabel,
    this.fieldHint,
  });

  final String title;
  final String description;
  final String confirmLabel;
  final double? saldo;
  final String? fieldLabel;
  final String? fieldHint;

  @override
  State<_InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<_InputDialog> {
  late final TextEditingController _amount = TextEditingController(
    text: widget.saldo == null ? '' : formatThousands(widget.saldo!),
  );
  final TextEditingController _text = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _text.dispose();
    super.dispose();
  }

  void _confirm() {
    final double? saldo = widget.saldo;
    double? monto;
    if (saldo != null) {
      monto = parseMoney(_amount.text);
      if (monto <= 0) {
        setState(() => _error = 'Ingresa un monto mayor a 0.');
        return;
      }
      if (monto > saldo) {
        setState(
          () => _error =
              'No puede superar el saldo pendiente (${formatCop(saldo)}).',
        );
        return;
      }
    }
    Navigator.of(context)
        .pop(_InputResult(monto: monto, texto: _text.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(widget.description),
          if (widget.saldo != null) ...<Widget>[
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                ThousandsInputFormatter(),
              ],
              decoration: InputDecoration(
                labelText: 'Monto (COP)',
                prefixText: '\$ ',
                errorText: _error,
              ),
            ),
          ],
          if (widget.fieldLabel != null) ...<Widget>[
            const SizedBox(height: 12),
            TextField(
              controller: _text,
              decoration: InputDecoration(
                labelText: widget.fieldLabel,
                hintText: widget.fieldHint,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _confirm(),
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _confirm, child: Text(widget.confirmLabel)),
      ],
    );
  }
}

class _ContributionTile extends StatelessWidget {
  const _ContributionTile({
    required this.name,
    required this.contribution,
    required this.canRegister,
    required this.canPayTotal,
    required this.canReport,
    required this.canReview,
    required this.onDetail,
    required this.onRegister,
    required this.onPayTotal,
    required this.onReport,
    required this.onReview,
  });

  final String name;
  final Contribution contribution;
  final bool canRegister;
  final bool canPayTotal;
  final bool canReport;
  final bool canReview;
  final VoidCallback onDetail;
  final VoidCallback onRegister;
  final VoidCallback onPayTotal;
  final VoidCallback onReport;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
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
                      if (contribution.isParcial) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          'Abonado ${formatCop(contribution.cobrado)} · saldo ${formatCop(contribution.saldoPendiente)}',
                          style: AppTextStyles.tiny.copyWith(
                            color: AppColors.ink2,
                          ),
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
            const Divider(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                children: <Widget>[
                  TextButton(onPressed: onDetail, child: const Text('Detalle')),
                  if (canReview)
                    TextButton(
                      onPressed: onReview,
                      child: const Text('Revisar abono'),
                    ),
                  if (canReport)
                    TextButton(
                      onPressed: onReport,
                      child: const Text('Reportar pago'),
                    ),
                  if (canRegister)
                    TextButton(
                      onPressed: onRegister,
                      child: const Text('Registrar abono'),
                    ),
                  if (canPayTotal)
                    TextButton(
                      onPressed: onPayTotal,
                      child: const Text('Pago total'),
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

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({
    required this.name,
    required this.contribution,
    required this.isTreasurer,
    required this.canReport,
    required this.canRegister,
    required this.onReport,
    required this.onRegister,
    required this.onApprove,
    required this.onReject,
    required this.onVoid,
  });

  final String name;
  final Contribution contribution;
  final bool isTreasurer;
  final bool canReport;
  final bool canRegister;
  final VoidCallback onReport;
  final VoidCallback onRegister;
  final void Function(Abono abono) onApprove;
  final void Function(Abono abono) onReject;
  final void Function(Abono abono) onVoid;

  @override
  Widget build(BuildContext context) {
    final Contribution item = contribution;
    final double progress = item.monto <= 0
        ? 0
        : (item.cobrado / item.monto).clamp(0, 1).toDouble();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(name, style: AppTextStyles.h4),
            const SizedBox(height: 4),
            Text(
              item.concepto.isEmpty
                  ? formatMonth(item.mes)
                  : '${formatMonth(item.mes)} · ${item.concepto}',
              style: AppTextStyles.small.copyWith(color: AppColors.ink2),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _Figure(label: 'Cuota', value: formatCop(item.monto)),
                ),
                Expanded(
                  child: _Figure(
                    label: 'Abonado',
                    value: formatCop(item.cobrado),
                  ),
                ),
                Expanded(
                  child: _Figure(
                    label: 'Saldo',
                    value: formatCop(item.saldoPendiente),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: AppColors.ok,
              backgroundColor: AppColors.mist,
            ),
            const SizedBox(height: 20),
            const SectionLabel('Abonos'),
            if (item.abonos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Aún no hay abonos registrados.',
                  style: AppTextStyles.small.copyWith(color: AppColors.ink3),
                ),
              )
            else
              for (final Abono abono in item.abonos)
                _AbonoRow(
                  abono: abono,
                  isTreasurer: isTreasurer,
                  onApprove: () => onApprove(abono),
                  onReject: () => onReject(abono),
                  onVoid: () => onVoid(abono),
                ),
            if (canReport) ...<Widget>[
              const SizedBox(height: 16),
              PrimaryButton(label: 'Reportar pago', onPressed: onReport),
            ],
            if (canRegister) ...<Widget>[
              const SizedBox(height: 16),
              SecondaryButton(label: 'Registrar abono', onPressed: onRegister),
            ],
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: AppTextStyles.tiny.copyWith(color: AppColors.ink3)),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.moneySmall),
      ],
    );
  }
}

class _AbonoRow extends StatelessWidget {
  const _AbonoRow({
    required this.abono,
    required this.isTreasurer,
    required this.onApprove,
    required this.onReject,
    required this.onVoid,
  });

  final Abono abono;
  final bool isTreasurer;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onVoid;

  @override
  Widget build(BuildContext context) {
    final List<String> details = <String>[
      abono.estado.label,
      if (abono.fecha != null) formatShortDate(abono.fecha),
      if (abono.referencia != null) 'Ref. ${abono.referencia}',
      if (abono.motivo != null) 'Motivo: ${abono.motivo}',
    ];
    final bool canApprove =
        isTreasurer && abono.estado == AbonoStatus.reportado;
    final bool canVoid = isTreasurer && abono.estado == AbonoStatus.aprobado;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(formatCop(abono.monto), style: AppTextStyles.moneyTiny),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  details.join(' · '),
                  style: AppTextStyles.tiny.copyWith(color: AppColors.ink2),
                ),
              ),
            ],
          ),
          if (canApprove || canVoid)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                if (canApprove)
                  TextButton(
                    onPressed: onReject,
                    child: const Text('Rechazar'),
                  ),
                if (canApprove)
                  FilledButton(
                    onPressed: onApprove,
                    child: const Text('Aprobar'),
                  ),
                if (canVoid)
                  TextButton(onPressed: onVoid, child: const Text('Anular')),
              ],
            ),
        ],
      ),
    );
  }
}
