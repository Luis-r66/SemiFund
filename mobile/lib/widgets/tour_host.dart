import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/session_provider.dart';
import 'app_tour.dart';
import 'guided_intro.dart';

/// Hospeda el recorrido por encima del navegador.
///
/// Como vive por fuera de las rutas, la guía no se cierra cuando cambia de
/// pantalla: ella misma navega, mide el widget señalado y sigue con el paso
/// siguiente. Se abre cuando la sesión lo pide (`tutorialPendiente` la primera
/// vez o `introSolicitada` desde el perfil).
class TourHost extends StatefulWidget {
  const TourHost({
    super.key,
    required this.child,
    required this.router,
    required this.session,
  });

  final Widget child;
  final GoRouter router;
  final SessionProvider session;

  @override
  State<TourHost> createState() => _TourHostState();
}

class _TourHostState extends State<TourHost> {
  List<GuidedStep> _pasos = const <GuidedStep>[];
  int _indice = 0;
  bool _visible = false;
  String? _rutaActual;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_revisar);
    WidgetsBinding.instance.addPostFrameCallback((_) => _revisar());
  }

  @override
  void didUpdateWidget(covariant TourHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      oldWidget.session.removeListener(_revisar);
      widget.session.addListener(_revisar);
    }
  }

  @override
  void dispose() {
    widget.session.removeListener(_revisar);
    super.dispose();
  }

  void _revisar() {
    if (!mounted || _visible) return;
    final SessionProvider session = widget.session;
    if (!session.isAuthenticated || !session.hasActiveSemillero) return;
    if (!session.isProfileComplete) return;
    if (!session.introSolicitada && !session.tutorialPendiente) return;

    final List<GuidedStep> pasos = AppTour.pasosPara(
      tesorero: session.isTesorero,
      profesor: session.user?.esProfesor ?? false,
    );
    if (pasos.isEmpty) return;

    // Se marca al empezar: si la app se cierra a mitad del recorrido no vuelve
    // a saltar sola en cada inicio. Desde el perfil se puede repetir.
    session.consumirIntroduccion();
    unawaited(session.marcarTutorialVisto());

    setState(() {
      _pasos = pasos;
      _indice = 0;
      _visible = true;
    });
    _abrir(0);
  }

  void _abrir(int indice) {
    final GuidedStep paso = _pasos[indice];
    setState(() => _indice = indice);
    final String? ruta = paso.route;
    if (ruta != null && ruta != _rutaActual) {
      _rutaActual = ruta;
      widget.router.go(ruta);
    }
  }

  void _siguiente() {
    if (_indice >= _pasos.length - 1) {
      _cerrar();
      return;
    }
    _abrir(_indice + 1);
  }

  void _cerrar() {
    if (!_visible) return;
    setState(() => _visible = false);
    _rutaActual = '/home';
    if (widget.session.isAuthenticated) widget.router.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        widget.child,
        if (_visible && _pasos.isNotEmpty)
          Positioned.fill(
            child: GuidedIntroLayer(
              key: ValueKey<int>(_indice),
              step: _pasos[_indice],
              index: _indice,
              total: _pasos.length,
              onSkip: _cerrar,
              onNext: _siguiente,
            ),
          ),
      ],
    );
  }
}
