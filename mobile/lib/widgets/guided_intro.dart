import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../widgets/buttons.dart';

/// Un paso del recorrido: si [target] apunta a un widget visible, la nube se
/// coloca junto a él y el resto de la pantalla se atenúa alrededor. [route] es
/// la pantalla que debe estar abierta para mostrar el paso.
class GuidedStep {
  const GuidedStep({
    required this.icon,
    required this.title,
    required this.body,
    this.target,
    this.route,
  });

  final IconData icon;
  final String title;
  final String body;
  final GlobalKey? target;
  final String? route;
}

/// Capa visual del recorrido: atenúa la pantalla, deja un hueco sobre el widget
/// señalado y muestra la tarjeta con el paso actual. Vive encima del navegador
/// (ver `TourHost`), así sobrevive a los cambios de pantalla.
class GuidedIntroLayer extends StatefulWidget {
  const GuidedIntroLayer({
    super.key,
    required this.step,
    required this.index,
    required this.total,
    required this.onSkip,
    required this.onNext,
  });

  final GuidedStep step;
  final int index;
  final int total;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  State<GuidedIntroLayer> createState() => _GuidedIntroLayerState();
}

class _GuidedIntroLayerState extends State<GuidedIntroLayer> {
  /// La pantalla de destino puede tardar en montarse: se reintenta la medición
  /// durante unos segundos antes de mostrar la tarjeta centrada.
  static const int _maxIntentos = 40;
  static const Duration _espera = Duration(milliseconds: 80);

  Rect? _targetRect;
  double _cardTop = 0;
  double _cardLeft = 0;
  double _cardWidth = 340;
  int _intentos = 0;
  bool _colocada = false;
  bool _reintentoFinal = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _medir());
  }

  Rect? _rectDelObjetivo() {
    final GlobalKey? clave = widget.step.target;
    if (clave == null) return null;
    final BuildContext? objetivo = clave.currentContext;
    if (objetivo == null) return null;
    final RenderObject? render = objetivo.findRenderObject();
    if (render is! RenderBox || !render.hasSize) return null;

    final Size pantalla = MediaQuery.sizeOf(context);
    final Offset origen = render.localToGlobal(Offset.zero);
    final Rect visible = (origen & render.size).intersect(
      Offset.zero & pantalla,
    );
    if (visible.width > 8 && visible.height > 8) return visible;
    return null;
  }

  void _medir() {
    if (!mounted) return;
    final Rect? rect = _rectDelObjetivo();
    if (rect == null &&
        widget.step.target != null &&
        _intentos < _maxIntentos) {
      _intentos += 1;
      unawaited(
        Future<void>.delayed(_espera, () {
          if (mounted) _medir();
        }),
      );
      return;
    }
    _colocar(rect);
  }

  void _colocar(Rect? rect) {
    final Size pantalla = MediaQuery.sizeOf(context);
    final double ancho = math.min(360, pantalla.width - 32);
    const double altoEstimado = 300;

    final double izquierda = rect == null
        ? (pantalla.width - ancho) / 2
        : (rect.center.dx - ancho / 2).clamp(
            16.0,
            math.max(16.0, pantalla.width - ancho - 16),
          );
    final bool debajo = rect == null || rect.center.dy < pantalla.height * 0.55;
    double arriba;
    if (rect == null) {
      arriba = (pantalla.height - altoEstimado) / 2;
    } else if (debajo) {
      arriba = rect.bottom + 16;
    } else {
      arriba = rect.top - altoEstimado - 16;
    }
    arriba = arriba.clamp(
      16.0,
      math.max(16.0, pantalla.height - altoEstimado - 16),
    );

    setState(() {
      _targetRect = rect;
      _cardWidth = ancho;
      _cardLeft = izquierda;
      _cardTop = arriba;
      _colocada = true;
    });

    // La transición entre pantallas puede mover el widget señalado: se vuelve
    // a medir una vez que la animación terminó para que el hueco quede justo.
    if (!_reintentoFinal) {
      _reintentoFinal = true;
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _medir();
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: <Widget>[
          // Absorbe los toques para que la pantalla de fondo no cambie
          // mientras se explica cada paso.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: CustomPaint(painter: _SpotlightPainter(hole: _targetRect)),
            ),
          ),
          if (_colocada)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              left: _cardLeft,
              top: _cardTop,
              width: _cardWidth,
              child: _IntroCard(
                step: widget.step,
                index: widget.index,
                total: widget.total,
                onSkip: widget.onSkip,
                onNext: widget.onNext,
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Center(
              child: TextButton(
                onPressed: widget.onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.paper,
                  backgroundColor: AppColors.ink.withValues(alpha: 0.55),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text('Saltar introducción'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.step,
    required this.index,
    required this.total,
    required this.onSkip,
    required this.onNext,
  });

  final GuidedStep step;
  final int index;
  final int total;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      elevation: 0,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.line),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 30,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: <Widget>[
            // Nube tenue de fondo: el detalle amable del recorrido.
            Positioned(
              right: -14,
              top: -20,
              child: Icon(
                LucideIcons.cloud,
                size: 112,
                color: AppColors.mist.withValues(alpha: 0.9),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: AppColors.mist,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(step.icon, size: 19, color: AppColors.ink),
                      ),
                      const Spacer(),
                      Text(
                        '${index + 1} / $total',
                        style: AppTextStyles.tinyMedium.copyWith(
                          color: AppColors.ink3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(step.title, style: AppTextStyles.h4),
                  const SizedBox(height: 8),
                  Text(
                    step.body,
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.ink2,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      TextButton(
                        onPressed: onSkip,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.ink2,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        child: const Text('Saltar'),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 136,
                        child: PrimaryButton(
                          label: index == total - 1 ? 'Listo' : 'Siguiente',
                          onPressed: onNext,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({required this.hole});

  final Rect? hole;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint oscuro = Paint()..color = AppColors.ink.withValues(alpha: 0.6);

    final Path fondo = Path()..addRect(Offset.zero & size);

    final Rect? actual = hole;
    if (actual == null) {
      canvas.drawPath(fondo, oscuro);
      return;
    }

    final RRect recorte = RRect.fromRectAndRadius(
      actual.inflate(6),
      const Radius.circular(18),
    );
    final Path camino = Path.combine(
      PathOperation.difference,
      fondo,
      Path()..addRRect(recorte),
    );
    canvas.drawPath(camino, oscuro);
    canvas.drawRRect(
      recorte,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.paper.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.hole != hole;
}
