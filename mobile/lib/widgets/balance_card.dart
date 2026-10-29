import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/formatters.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.saldo, required this.updatedAt});

  final double saldo;
  final DateTime updatedAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Saldo disponible',
            style: AppTextStyles.smallMedium.copyWith(
              color: const Color(0x99FFFFFF),
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatCop(saldo),
              style: AppTextStyles.moneyLarge.copyWith(color: AppColors.paper),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5FD38D),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'Actualizado hoy, ${formatDayMonth(updatedAt)}',
                  style: AppTextStyles.tinyMedium.copyWith(
                    color: AppColors.paper,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
