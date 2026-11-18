import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Vuelve a la pantalla anterior. Si la pantalla se abrió directamente (por
/// ejemplo desde la barra lateral de la web) no hay pila que retroceder, así
/// que va al inicio en lugar de cerrar la app.
void volver(BuildContext context, {String fallback = '/home'}) {
  final GoRouter router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
  } else {
    router.go(fallback);
  }
}
