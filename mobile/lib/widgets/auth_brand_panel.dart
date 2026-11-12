import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import 'app_logo.dart';

/// Panel de marca que acompaña a los formularios de acceso en escritorio.
class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({super.key});

  static const Color _onDark = Color(0xFFB9BEC4);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.ink,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool narrow = constraints.maxWidth < 480;
            final double horizontal = narrow ? 36 : 56;

            return Padding(
              padding: EdgeInsets.fromLTRB(horizontal, 44, horizontal, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const AppLogo(size: 48, showLabel: false, light: true),
                  const Spacer(),
                  Text(
                    'La tesorería de tu semillero, clara y compartida.',
                    style: AppTextStyles.display.copyWith(
                      color: AppColors.paper,
                      fontSize: narrow ? 30 : 38,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const _BrandBenefit(
                    text: 'Saldo, aportes y gastos en un solo lugar.',
                  ),
                  const SizedBox(height: 14),
                  const _BrandBenefit(
                    text: 'Cada integrante ve lo mismo, sin hojas de cálculo sueltas.',
                  ),
                  const SizedBox(height: 14),
                  const _BrandBenefit(
                    text: 'Comprobantes y estados de cuenta listos para descargar.',
                  ),
                  const Spacer(),
                  Text(
                    'SEMIFUND · GESTIÓN DE TESORERÍA',
                    style: AppTextStyles.label.copyWith(
                      color: _onDark,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrandBenefit extends StatelessWidget {
  const _BrandBenefit({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.only(top: 1),
          decoration: const BoxDecoration(
            color: Color(0x1FFFFFFF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.check,
            size: 12,
            color: AppColors.paper,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.small.copyWith(color: AuthBrandPanel._onDark),
          ),
        ),
      ],
    );
  }
}
