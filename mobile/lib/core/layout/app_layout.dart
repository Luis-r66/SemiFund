import 'package:flutter/material.dart';

/// Puntos de corte y anchos máximos para la versión web.
///
/// En móvil no cambia nada: las pantallas siguen ocupando todo el ancho.
class AppLayout {
  const AppLayout._();

  /// Debajo de este ancho la interfaz se considera móvil.
  static const double compactMax = 600;

  /// Desde este ancho hay espacio para un diseño de escritorio.
  static const double desktopMin = 1024;

  /// Formularios y pantallas de una sola columna.
  static const double formMaxWidth = 640;

  /// Listas, tableros y contenido general.
  static const double contentMaxWidth = 1280;

  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool isCompact(BuildContext context) => widthOf(context) < compactMax;

  static bool isDesktop(BuildContext context) => widthOf(context) >= desktopMin;
}

/// Centra el contenido y limita su ancho para que no se estire de lado a lado
/// en pantallas grandes. En móvil no tiene efecto.
class AppContent extends StatelessWidget {
  const AppContent({
    super.key,
    required this.child,
    this.maxWidth = AppLayout.contentMaxWidth,
    this.padding = EdgeInsets.zero,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final bool unbounded = AppLayout.isCompact(context);

    final Widget constrained = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Padding(padding: padding, child: child),
    );

    if (unbounded) return constrained;
    return Align(alignment: alignment, child: constrained);
  }
}
