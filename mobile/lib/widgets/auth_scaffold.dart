import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/layout/app_layout.dart';
import '../core/theme/app_colors.dart';
import 'auth_brand_panel.dart';

/// Marco común de las pantallas de acceso.
///
/// En móvil mantiene la columna con los botones fijos abajo. En escritorio
/// muestra un recuadro centrado: marca a la izquierda, formulario a la derecha.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.form, required this.actions});

  final Widget form;
  final Widget actions;

  /// Ancho y alto máximos del recuadro de escritorio.
  static const double _cardMaxWidth = 1000;
  static const double _cardMaxHeight = 780;
  static const double _cardMargin = 64;
  static const double _cardRadius = 20;

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
      backgroundColor: AppColors.mist,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = math.min(
              constraints.maxWidth - _cardMargin,
              _cardMaxWidth,
            );
            final double height = math.min(
              constraints.maxHeight - _cardMargin,
              _cardMaxHeight,
            );

            return Center(
              child: SizedBox(
                width: width,
                height: height,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(_cardRadius),
                    border: Border.all(color: AppColors.line),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 32,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_cardRadius),
                    child: Row(
                      children: <Widget>[
                        const Expanded(flex: 5, child: AuthBrandPanel()),
                        Expanded(
                          flex: 6,
                          child: _FormPane(form: form, actions: actions),
                        ),
                      ],
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
}

/// Columna derecha del recuadro: centra el formulario y deja que se desplace
/// cuando no cabe en el alto disponible.
class _FormPane extends StatefulWidget {
  const _FormPane({required this.form, required this.actions});

  final Widget form;
  final Widget actions;

  @override
  State<_FormPane> createState() => _FormPaneState();
}

class _FormPaneState extends State<_FormPane> {
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: 40,
    vertical: 20,
  );

  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Si el recuadro está limitado por la altura de la ventana, los botones
        // se quedan fijos abajo y solo el formulario se desplaza: así la acción
        // principal nunca queda fuera de la vista en pantallas bajas.
        if (constraints.maxHeight < AuthScaffold._cardMaxHeight) {
          return Column(
            children: <Widget>[
              Expanded(
                child: Scrollbar(
                  controller: _scroll,
                  thumbVisibility: true,
                  thickness: 4,
                  radius: const Radius.circular(4),
                  child: SingleChildScrollView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(40, 20, 40, 8),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: widget.form,
                      ),
                    ),
                  ),
                ),
              ),
              // Barra fija: el formulario se desplaza por detrás y la acción
              // principal siempre queda visible, incluso en ventanas bajas.
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.paper,
                  border: Border(top: BorderSide(color: AppColors.line)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(40, 16, 40, 20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: widget.actions,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return SingleChildScrollView(
          padding: _padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, constraints.maxHeight - _padding.vertical),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    widget.form,
                    const SizedBox(height: 20),
                    widget.actions,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
