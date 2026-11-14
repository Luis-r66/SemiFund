import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// Muestra un check animado durante un instante, con una vibración corta.
/// Se usa al guardar aportes y gastos, justo antes de volver atrás.
Future<void> showSuccessCheck(
  BuildContext context, {
  String message = 'Guardado',
  Duration duration = const Duration(milliseconds: 850),
}) async {
  final bool reduceMotion =
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  if (!reduceMotion) {
    HapticFeedback.lightImpact();
  }
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: message,
    barrierColor: AppColors.ink.withValues(alpha: 0.18),
    transitionDuration: reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 180),
    pageBuilder: (BuildContext dialogContext, _, _) {
      return _SuccessOverlay(message: message, duration: duration);
    },
    transitionBuilder:
        (BuildContext context, Animation<double> animation, _, Widget child) {
          return FadeTransition(opacity: animation, child: child);
        },
  );
}

class _SuccessOverlay extends StatefulWidget {
  const _SuccessOverlay({required this.message, required this.duration});

  final String message;
  final Duration duration;

  @override
  State<_SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<_SuccessOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    Future<void>.delayed(widget.duration, () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 150,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(22),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.16),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 62,
                height: 62,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (BuildContext context, _) {
                    return CustomPaint(
                      painter: _CheckPainter(
                        progress: reduceMotion ? 1 : _controller.value,
                        reduceMotion: reduceMotion,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: AppTextStyles.smallSemibold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dibuja un círculo que se llena y un check que se traza encima.
class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.progress, required this.reduceMotion});

  final double progress;
  final bool reduceMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radio = size.width / 2 - 2;

    final Paint fondo = Paint()..color = AppColors.okSoft;
    canvas.drawCircle(center, radio, fondo);

    final double trazo = Curves.easeOutCubic.transform(progress);

    final Paint anillo = Paint()
      ..color = AppColors.ok
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radio - 1.5),
      -math.pi / 2,
      2 * math.pi * trazo,
      false,
      anillo,
    );

    if (reduceMotion || progress > 0.35) {
      final double checkProgress = reduceMotion
          ? 1
          : ((progress - 0.35) / 0.5).clamp(0.0, 1.0);
      final Path path = Path()
        ..moveTo(size.width * 0.30, size.height * 0.52)
        ..lineTo(size.width * 0.44, size.height * 0.66)
        ..lineTo(size.width * 0.71, size.height * 0.37);

      final PathMetric metric = path.computeMetrics().first;
      final Paint check = Paint()
        ..color = AppColors.ok
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(
        metric.extractPath(0, metric.length * checkProgress),
        check,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
