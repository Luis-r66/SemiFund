import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/layout/app_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/buttons.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool desktop = AppLayout.isDesktop(context);

    if (!desktop) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 28),
                const AppLogo(size: 52),
                const SizedBox(height: 30),
                Text(
                  'La tesorería de tu semillero, clara y compartida.',
                  style: AppTextStyles.display,
                ),
                const SizedBox(height: 26),
                ..._benefits,
                const Spacer(),
                ..._actions(context),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 48,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const AppLogo(size: 52),
                          const SizedBox(height: 34),
                          Text(
                            'La tesorería de tu semillero, clara y compartida.',
                            style: AppTextStyles.display.copyWith(
                              fontSize: 40,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 28),
                          ..._benefits,
                          const SizedBox(height: 44),
                          ..._actions(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> get _benefits => const <Widget>[
    _Benefit(text: 'Saldo, aportes y gastos de tu semillero en un solo lugar.'),
    SizedBox(height: 14),
    _Benefit(text: 'Únete con un código y espera la aprobación del tesorero.'),
    SizedBox(height: 14),
    _Benefit(text: 'Administra varios semilleros con la misma cuenta.'),
  ];

  List<Widget> _actions(BuildContext context) => <Widget>[
    PrimaryButton(
      label: 'Iniciar sesión',
      onPressed: () => context.push('/login'),
    ),
    const SizedBox(height: 10),
    SecondaryButton(
      label: 'Crear cuenta',
      onPressed: () => context.push('/register'),
    ),
  ];
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.text});

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
            color: AppColors.okSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.check, size: 12, color: AppColors.ok),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.small.copyWith(color: AppColors.ink2),
          ),
        ),
      ],
    );
  }
}
