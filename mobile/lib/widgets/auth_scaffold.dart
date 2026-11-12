import 'package:flutter/material.dart';

import '../core/layout/app_layout.dart';
import '../core/theme/app_colors.dart';
import 'auth_brand_panel.dart';

/// Marco común de las pantallas de acceso.
///
/// En móvil mantiene la columna con los botones fijos abajo. En escritorio
/// divide la pantalla: marca a la izquierda, formulario centrado a la derecha.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.form, required this.actions});

  final Widget form;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    if (!AppLayout.isDesktop(context)) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: form,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: actions,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Row(
        children: <Widget>[
          const Expanded(flex: 5, child: AuthBrandPanel()),
          Expanded(
            flex: 6,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        form,
                        const SizedBox(height: 20),
                        actions,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
