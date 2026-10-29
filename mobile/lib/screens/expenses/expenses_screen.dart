import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/expense.dart';
import '../../providers/expenses_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/section_label.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ExpensesProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ExpensesProvider expenses = context.watch<ExpensesProvider>();
    final bool isTreasurer = context.watch<SessionProvider>().isTesorero;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AppTopBar(
              title: 'Gastos',
              onBack: () => context.pop(),
              trailing: isTreasurer
                  ? RoundAddButton(
                      onPressed: () => context.push('/expenses/new'),
                    )
                  : null,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: expenses.load,
                color: AppColors.ink,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: <Widget>[
                    if (expenses.error != null) ...<Widget>[
                      ErrorBanner(
                        message: expenses.error!,
                        onRetry: expenses.load,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (expenses.loading && expenses.expenses.isEmpty)
                      const SizedBox(height: 360, child: LoadingView())
                    else ...<Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 18),
                        child: Row(
                          children: <Widget>[
                            Text(
                              'Total gastado',
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.ink2,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              formatCop(expenses.balance.totalGastado),
                              style: AppTextStyles.moneyTiny.copyWith(
                                color: AppColors.ink,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (expenses.expenses.isEmpty)
                        const EmptyState(
                          icon: LucideIcons.receipt,
                          title: 'Sin gastos registrados',
                          message: 'Los gastos del semillero aparecerán aquí.',
                        )
                      else ...<Widget>[
                        SectionLabel('${expenses.expenses.length} registrados'),
                        for (final Expense expense in expenses.expenses)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ExpenseTile(expense: expense),
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

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
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
                Text(expense.descripcion, style: AppTextStyles.bodySemibold),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mist,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        expense.categoriaLabel,
                        style: AppTextStyles.tinyMedium.copyWith(
                          color: AppColors.ink2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatShortDate(expense.fecha),
                      style: AppTextStyles.tiny.copyWith(color: AppColors.ink3),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '-${formatCop(expense.monto)}',
            style: AppTextStyles.moneySmall.copyWith(color: AppColors.bad),
          ),
        ],
      ),
    );
  }
}
