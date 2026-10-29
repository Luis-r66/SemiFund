import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../providers/expenses_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/buttons.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/form_controls.dart';

class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final TextEditingController _description = TextEditingController();
  final TextEditingController _amount = TextEditingController();

  String? _category;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _description.addListener(() => setState(() {}));
    _amount.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ExpensesProvider>().load();
    });
  }

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  double get _montoValue => parseMoney(_amount.text);

  bool get _overBudget =>
      _montoValue > context.read<ExpensesProvider>().balance.saldoDisponible;

  bool get _canSave =>
      _description.text.trim().isNotEmpty &&
      _category != null &&
      _montoValue > 0 &&
      !_overBudget &&
      !_saving;

  Future<void> _save() async {
    if (!_canSave) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<ExpensesProvider>().create(
        descripcion: _description.text.trim(),
        categoria: _category!.toLowerCase(),
        monto: _montoValue,
      );
      if (!mounted) return;
      context.pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      // 409 del backend: saldo insuficiente (el saldo puede haber cambiado).
      setState(() => _error = error.message);
      if (error.isConflict) {
        context.read<ExpensesProvider>().load();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ExpensesProvider expenses = context.watch<ExpensesProvider>();
    final double available = expenses.balance.saldoDisponible;
    final bool over = _montoValue > available;
    final double remaining = available - _montoValue;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AppTopBar(title: 'Nuevo gasto', onBack: () => context.pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    LabeledField(
                      label: 'Descripción',
                      child: AppTextField(
                        controller: _description,
                        hintText: 'Ej. Camisetas del semillero',
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    LabeledField(
                      label: 'Categoría',
                      child: SelectField<String>(
                        value: _category,
                        items: expenseCategories,
                        labelOf: (String item) => item,
                        hintText: 'Selecciona una categoría',
                        onChanged: (String? value) =>
                            setState(() => _category = value),
                      ),
                    ),
                    LabeledField(
                      label: 'Monto (COP)',
                      child: MoneyField(controller: _amount, invalid: over),
                    ),
                    if (over) ...<Widget>[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ErrorBanner(
                          message:
                              'Saldo insuficiente. Disponible: ${formatCop(available)}',
                        ),
                      ),
                    ],
                    if (!over && _montoValue > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16, left: 4),
                        child: Text.rich(
                          TextSpan(
                            text: 'Saldo tras el gasto: ',
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.ink2,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: formatCop(remaining),
                                style: AppTextStyles.moneyTiny.copyWith(
                                  color: AppColors.ok,
                                ),
                              ),
                            ],
                          ),
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
                label: 'Guardar gasto',
                loading: _saving,
                onPressed: _canSave ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
