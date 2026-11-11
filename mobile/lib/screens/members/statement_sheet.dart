import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/contribution.dart';
import '../../models/member.dart';
import '../../models/member_statement.dart';
import '../../services/dashboard_service.dart';
import '../../services/statement_pdf.dart';
import '../../widgets/buttons.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/section_label.dart';
import '../../widgets/status_badge.dart';

Future<void> showStatementSheet(BuildContext context, Member member) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => _StatementSheet(member: member),
  );
}

class _StatementSheet extends StatefulWidget {
  const _StatementSheet({required this.member});

  final Member member;

  @override
  State<_StatementSheet> createState() => _StatementSheetState();
}

class _StatementSheetState extends State<_StatementSheet> {
  late Future<MemberStatement> _future = _load();
  bool _sharing = false;

  Future<MemberStatement> _load() {
    return context.read<DashboardService>().memberStatement(widget.member.id);
  }

  Future<void> _share(MemberStatement statement) async {
    setState(() => _sharing = true);
    try {
      final Uint8List bytes = await buildMemberStatementPdf(
        widget.member,
        statement,
      );
      await Printing.sharePdf(bytes: bytes, filename: 'estado_cuenta.pdf');
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo generar el PDF del estado de cuenta.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<MemberStatement>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<MemberStatement> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(height: 240, child: LoadingView());
          }
          if (snapshot.hasError) {
            final Object error = snapshot.error!;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: ErrorBanner(
                message: error is ApiException
                    ? error.message
                    : 'No se pudo cargar el estado de cuenta.',
                onRetry: () => setState(() => _future = _load()),
              ),
            );
          }
          final MemberStatement statement = snapshot.requireData;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        widget.member.nombre,
                        style: AppTextStyles.h4,
                      ),
                    ),
                    StatusBadge(
                      label: statement.alDia ? 'Al dÃ­a' : 'Con saldo',
                      tone: statement.alDia ? BadgeTone.ok : BadgeTone.warn,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _Figure(
                        label: 'Cuotas',
                        value: formatCop(statement.esperado),
                      ),
                    ),
                    Expanded(
                      child: _Figure(
                        label: 'Pagado',
                        value: formatCop(statement.cobrado),
                      ),
                    ),
                    Expanded(
                      child: _Figure(
                        label: 'Saldo',
                        value: formatCop(statement.saldo),
                      ),
                    ),
                  ],
                ),
                if (statement.vencido > 0) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    'Vencido: ${formatCop(statement.vencido)}',
                    style: AppTextStyles.small.copyWith(color: AppColors.bad),
                  ),
                ],
                const SizedBox(height: 20),
                const SectionLabel('Cuotas'),
                if (statement.cuotas.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Este integrante no tiene cuotas.',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.ink3,
                      ),
                    ),
                  )
                else
                  for (final Contribution cuota in statement.cuotas)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              '${formatMonth(cuota.mes)} Â· ${formatCop(cuota.cobrado)} de ${formatCop(cuota.monto)}',
                              style: AppTextStyles.small,
                            ),
                          ),
                          StatusBadge.contribution(cuota),
                        ],
                      ),
                    ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: _sharing
                      ? 'Generando PDF...'
                      : 'Compartir estado de cuenta (PDF)',
                  icon: LucideIcons.share2,
                  onPressed: _sharing ? null : () => _share(statement),
                ),
              ],
            ),
          );
        },
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
