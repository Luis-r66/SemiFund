import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/layout/app_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/member.dart';
import '../../providers/contributions_provider.dart';
import '../../providers/members_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/buttons.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/form_controls.dart';
import '../../widgets/success_check.dart';

class ContributionFormScreen extends StatefulWidget {
  const ContributionFormScreen({super.key, this.hoy});

  /// Mes de referencia. En pruebas se fija para que los goldens no cambien
  /// cuando cambie el mes.
  final DateTime? hoy;

  @override
  State<ContributionFormScreen> createState() => _ContributionFormScreenState();
}

class _ContributionFormScreenState extends State<ContributionFormScreen> {
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _concept = TextEditingController();
  late final List<String> _months;

  Member? _member;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MembersProvider>().loadForPicker();
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _concept.dispose();
    super.dispose();
  }

  double get _montoValue => parseMoney(_amount.text);

  bool get _canSave =>
      _member != null &&
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
      await context.read<ContributionsProvider>().create(
        integranteId: _member!.id,
        monto: _montoValue,
        mes: _month!,
        concepto: _concept.text.trim(),
      );
      if (!mounted) return;
      await showSuccessCheck(context, message: 'Aporte registrado');
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
    final MembersProvider members = context.watch<MembersProvider>();
    final List<Member> active = members.pickerMembers;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: AppContent(
          maxWidth: AppLayout.formMaxWidth,
          child: Column(
            children: <Widget>[
              AppTopBar(title: 'Registrar aporte', onBack: () => context.pop()),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      LabeledField(
                        label: 'Integrante',
                        child: SelectField<Member>(
                          value: _member,
                          items: active,
                          labelOf: (Member item) => item.nombre,
                          hintText: members.loading
                              ? 'Cargando integrantes...'
                              : 'Selecciona un integrante',
                          onChanged: (Member? value) =>
                              setState(() => _member = value),
                        ),
                      ),
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
                        label: 'Monto (COP)',
                        child: MoneyField(controller: _amount),
                      ),
                      LabeledField(
                        label: 'Concepto',
                        child: AppTextField(
                          controller: _concept,
                          hintText: 'Ej. Cuota mensual',
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _save(),
                        ),
                      ),
                      if (members.error != null) ...<Widget>[
                        ErrorBanner(
                          message: members.error!,
                          onRetry: members.loadForPicker,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_error != null) ErrorBanner(message: _error!),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: PrimaryButton(
                  label: 'Registrar aporte',
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
