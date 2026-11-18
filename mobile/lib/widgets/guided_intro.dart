import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../widgets/buttons.dart';

/// Un paso del recorrido: si [target] apunta a un widget visible, la nube se
/// coloca junto a él y el resto de la pantalla se atenúa alrededor.
class GuidedStep {
  const GuidedStep({
    required this.icon,
    required this.title,
    required this.body,
    this.target,
  });

  final IconData icon;
  final String title;
  final String body;
  final GlobalKey? target;
}

/// Introducción guiada sobre la pantalla real, al estilo de las nubes de Lulo.
/// Se puede avanzar paso a paso o saltar; al terminar se marca como vista.
class GuidedIntro {
  const GuidedIntro._();

  static Future<void> mostrar(
    BuildContext context, {
    required List<GuidedStep> steps,
    VoidCallback? onDone,
  }) async {
    if (steps.isEmpty) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Introducción guiada',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => _GuidedIntroView(steps: steps),
      transitionBuilder:
          (BuildContext context, Animation<double> animation, _, Widget child) {
            final Animation<double> curva = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curva,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.98, end: 1).animate(curva),
                child: child,
              ),
            );
          },
    );
    onDone?.call();
  }
}

class _GuidedIntroView extends StatefulWidget {
  const _GuidedIntroView({required this.steps});

  final List<GuidedStep> steps;

  @override
  State<_GuidedIntroView> createState() => _GuidedIntroViewState();
}

class _GuidedIntroViewState extends State<_GuidedIntroView> {
  int _index = 0;
  Rect? _targetRect;
  double _cardTop = 0;
  double _cardLeft = 0;
  double _cardWidth = 340;

  GuidedStep get _step => widget.steps[_index];
  bool get _esUltimo => _index == widget.steps.length - 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _medir());
  }

  void _medir() {
    if (!mounted) return;
    final Size pantalla = MediaQuery.sizeOf(context);
    final BuildContext? objetivo = _step.target?.currentContext;
    Rect? rect;

    if (objetivo != null) {
      final RenderObject? render = objetivo.findRenderObject();
      if (render is RenderBox && render.hasSize) {
        final Offset origen = render.localToGlobal(Offset.zero);
        final Rect completo = origen & render.size;
        final Rect visible = completo.intersect(Offset.zero & pantalla);
        if (visible.width > 8 && visible.height > 8) rect = visible;
      }
    }

    final double ancho = math.min(360, pantalla.width - 32);
    final double estimado = 286;
    final double izquierda = rect == null
        ? (pantalla.width - ancho) / 2
        : (rect.center.dx - ancho / 2).clamp(
            16.0,
            math.max(16.0, pantalla.width - ancho - 16),
          );
    final bool debajo = rect == null || rect.center.dy < pantalla.height * 0.55;
    double arriba;
    if (rect == null) {
      arriba = (pantalla.height - estimado) / 2;
    } else if (debajo) {
      arriba = rect.bottom + 16;
    } else {
      arriba = rect.top - estimado - 16;
    }
    arriba = arriba.clamp(
      16.0,
      math.max(16.0, pantalla.height - estimado - 16),
    );

    setState(() {
      _targetRect = rect;
      _cardWidth = ancho;
      _cardLeft = izquierda;
      _cardTop = arriba;
    });
  }

  void _siguiente() {
    if (_esUltimo) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _index += 1;
      _targetRect = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _medir());
  }

  void _saltar() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(painter: _SpotlightPainter(hole: _targetRect)),
          ),
          Positioned(
            left: _cardLeft,
            top: _cardTop,
            width: _cardWidth,
            child: _IntroCard(
              step: _step,
              index: _index,
              total: widget.steps.length,
              onSkip: _saltar,
              onNext: _siguiente,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Center(
              child: TextButton(
                onPressed: _saltar,
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
