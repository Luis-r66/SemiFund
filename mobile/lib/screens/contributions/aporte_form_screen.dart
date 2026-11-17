import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/layout/app_layout.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/contribution.dart';
import '../../providers/contributions_provider.dart';
import '../../services/management_service.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/buttons.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/form_controls.dart';
import '../../widgets/success_check.dart';

/// Aporte grupal del tesorero: viaje, materiales u otro destino común.
/// No se escoge integrante: se crea la misma parte para todos los activos.
class AporteFormScreen extends StatefulWidget {
  const AporteFormScreen({super.key, this.hoy});

  final DateTime? hoy;

  @override
  State<AporteFormScreen> createState() => _AporteFormScreenState();
}

class _AporteFormScreenState extends State<AporteFormScreen> {
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _concept = TextEditingController();
  late final List<String> _months;

  String? _month;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final DateTime hoy = widget.hoy ?? DateTime.now();
    _months = monthOptions(hoy);
    _month = currentMonth(hoy);
    _amount.addListener(() => setState(() {}));
    _concept.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amount.dispose();
    _concept.dispose();
    super.dispose();
  }

  double get _montoValue => parseMoney(_amount.text);

  bool get _canSave =>
      _month != null &&
      _montoValue > 0 &&
      _concept.text.trim().isNotEmpty &&
      !_saving;

  Future<void> _save() async {
    if (!_canSave) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final BulkContributionResult result = await context
          .read<ContributionsProvider>()
          .createBulk(
            mes: _month!,
            monto: _montoValue,
            concepto: _concept.text.trim(),
            tipo: ContributionType.aporte,
          );
      if (!mounted) return;
      if (result.creadas == 0) {
        setState(() {
          _error = result.omitidas > 0
              ? 'No se creó el aporte: ya existía para ese mes o no hay integrantes activos.'
              : 'No hay integrantes activos para asignar el aporte.';
        });
        return;
      }
      await showSuccessCheck(
        context,
        message: result.creadas == 1
            ? 'Aporte creado'
            : '${result.creadas} aportes creados',
      );
      if (!mounted) return;
      context.pop();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: AppContent(
          maxWidth: AppLayout.formMaxWidth,
          child: Column(
            children: <Widget>[
              AppTopBar(title: 'Nuevo aporte', onBack: () => context.pop()),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'El aporte se crea para todos los integrantes activos. Cada uno reporta su pago y el tesorero lo aprueba.',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.ink2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      LabeledField(
                        label: 'Mes',
                        child: SelectField<String>(
                          value: _month,
                          items: _months,
                          labelOf: formatMonth,
                          hintText: 'Selecciona el mes',
                          onChanged: (String? value) =>
                              setState(() => _month = value),
                        ),
                      ),
                      LabeledField(
                        label: 'Monto por integrante (COP)',
                        child: MoneyField(controller: _amount),
                      ),
                      LabeledField(
                        label: 'Concepto',
                        child: AppTextField(
                          controller: _concept,
                          hintText: 'Ej. Viaje a Medellín',
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _save(),
                        ),
                      ),
                      if (_error != null) ErrorBanner(message: _error!),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: PrimaryButton(
                  label: 'Crear aporte',
                  loading: _saving,
                  onPressed: _canSave ? _save : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
