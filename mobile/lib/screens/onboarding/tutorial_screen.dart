import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/session_provider.dart';
import '../../widgets/buttons.dart';

class _TutorialStep {
  const _TutorialStep({
    required this.icon,
    required this.title,
    required this.body,
    required this.chips,
  });

  final IconData icon;
  final String title;
  final String body;
  final List<String> chips;
}

const List<_TutorialStep> _steps = <_TutorialStep>[
  _TutorialStep(
    icon: LucideIcons.building2,
    title: 'Todo tu semillero,\nen un solo lugar',
    body:
        'Crea el semillero o únete con el código que te comparte el tesorero. '
        'Aquí viven los integrantes, los aportes y los gastos.',
    chips: <String>['Integrantes', 'Código', 'Roles'],
  ),
  _TutorialStep(
    icon: LucideIcons.wallet,
    title: 'Aportes y cuotas\nsin enredos',
    body:
        'Registra las cuotas del mes, reporta tus abonos y mira de un vistazo '
        'quién está al día y cuánto falta por cobrar.',
    chips: <String>['Cuotas', 'Abonos', 'Al día'],
  ),
  _TutorialStep(
    icon: LucideIcons.receipt,
    title: 'Gastos claros,\nsaldo real',
    body:
        'Anota cada gasto con su comprobante y consulta el saldo disponible '
        'al instante, sin sumar en una hoja aparte.',
    chips: <String>['Gastos', 'Comprobantes', 'Saldo'],
  ),
  _TutorialStep(
    icon: LucideIcons.bell,
    title: 'Avisos que te\nmantienen al tanto',
    body:
        'Los abonos reportados, las cuotas nuevas y las invitaciones llegan '
        'a la campanita y, si quieres, también a tu correo.',
    chips: <String>['Campanita', 'Correo', 'Novedades'],
  ),
  _TutorialStep(
    icon: LucideIcons.sparkles,
    title: 'Listo para\nempezar',
    body:
        'Crea tu primer semillero o únete a uno que ya exista. Podrás repetir '
        'este recorrido cuando quieras desde tu perfil.',
    chips: <String>['Crear', 'Unirme', 'Empezar'],
  ),
];

/// Recorrido de bienvenida para cuentas nuevas. También se puede repetir
/// desde el perfil con `?replay=1`.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key, this.replay = false});

  final bool replay;

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pages = PageController();
  late final AnimationController _ambiente = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  int _actual = 0;
  bool _terminando = false;

  @override
  void dispose() {
    _pages.dispose();
    _ambiente.dispose();
    super.dispose();
  }

  Future<void> _terminar() async {
    if (_terminando) return;
    setState(() => _terminando = true);
    await context.read<SessionProvider>().marcarTutorialVisto();
    if (!mounted) return;
    if (widget.replay && context.canPop()) {
      context.pop();
    } else {
      context.go('/semilleros');
    }
  }

  void _siguiente() {
    if (_actual >= _steps.length - 1) {
      _terminar();
      return;
    }
    _pages.nextPage(
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }

  void _atras() {
    if (_actual == 0) return;
    _pages.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool ultimo = _actual == _steps.length - 1;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 12, 4),
              child: Row(
                children: <Widget>[
                  Text(
                    'SEMIFUND',
                    style: AppTextStyles.tinySemibold.copyWith(
                      letterSpacing: 2.4,
                      color: AppColors.ink,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _terminando ? null : _terminar,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.ink2,
                      textStyle: AppTextStyles.smallMedium,
                    ),
                    child: const Text('Saltar'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _steps.length,
                onPageChanged: (int value) => setState(() => _actual = value),
                itemBuilder: (BuildContext context, int index) {
                  return AnimatedBuilder(
                    animation: _pages,
                    builder: (BuildContext context, Widget? child) {
                      final double page =
                          _pages.hasClients && _pages.page != null
                          ? _pages.page!
                          : _actual.toDouble();
                      final double delta = (page - index).clamp(-1.0, 1.0);
                      return Opacity(
                        opacity: 1 - delta.abs() * 0.85,
                        child: Transform.translate(
                          offset: Offset(delta * 48, 0),
                          child: Transform.scale(
                            scale: 1 - delta.abs() * 0.06,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: _StepView(
                      step: _steps[index],
                      index: index,
                      ambiente: _ambiente,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(_steps.length, (int index) {
                  final bool activo = index == _actual;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: activo ? 24 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: activo ? AppColors.ink : AppColors.line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
              child: Row(
                children: <Widget>[
                  if (_actual > 0)
                    TextButton(
                      onPressed: _atras,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.ink2,
                        textStyle: AppTextStyles.button,
                        minimumSize: const Size(72, 52),
                      ),
                      child: const Text('Atrás'),
                    ),
                  if (_actual > 0) const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      label: ultimo ? 'Empezar' : 'Siguiente',
                      loading: _terminando,
                      onPressed: _terminando ? null : _siguiente,
                    ),
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

class _StepView extends StatelessWidget {
  const _StepView({
    required this.step,
    required this.index,
    required this.ambiente,
  });

  final _TutorialStep step;
  final int index;
  final Animation<double> ambiente;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: AnimatedBuilder(
                    animation: ambiente,
                    builder: (BuildContext context, Widget? child) {
                      final double t = ambiente.value * 2 * math.pi;
                      return Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          Container(
                            width: 208,
                            height: 208,
                            decoration: const BoxDecoration(
                              color: AppColors.mist,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Transform.rotate(
                            angle: t * 0.35,
                            child: Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                _orbitDot(108, 0),
                                _orbitDot(108, 128),
                                _orbitDot(108, 236),
                              ],
                            ),
                          ),
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.82, end: 1),
                            duration: const Duration(milliseconds: 620),
                            curve: Curves.elasticOut,
                            builder: (BuildContext context, double value, _) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  width: 104,
                                  height: 104,
                                  decoration: const BoxDecoration(
                                    color: AppColors.ink,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    step.icon,
                                    size: 42,
                                    color: AppColors.paper,
                                  ),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            right: 74,
                            bottom: 40,
                            child: Transform.translate(
                              offset: Offset(0, math.sin(t * 1.6) * 5),
                              child: const CustomPaint(
                                size: Size(40, 40),
                                painter: _MascotaPainter(),
                              ),
                            ),
                          ),
                          ..._chips(context, t),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  step.title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h1.copyWith(height: 1.1),
                ),
                const SizedBox(height: 14),
                Text(
                  step.body,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.ink2,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _orbitDot(double radius, double angleDeg) {
    final double angle = angleDeg * math.pi / 180;
    return Transform.translate(
      offset: Offset(math.cos(angle) * radius, math.sin(angle) * radius),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.ink3,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  List<Widget> _chips(BuildContext context, double t) {
    final List<Offset> posiciones = <Offset>[
      const Offset(4, 34),
      const Offset(232, 70),
      const Offset(18, 176),
    ];
    final List<Widget> chips = <Widget>[];
    for (int i = 0; i < step.chips.length && i < posiciones.length; i++) {
      chips.add(
        Positioned(
          left: posiciones[i].dx,
          top: posiciones[i].dy + math.sin(t + i) * 4,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(milliseconds: 420 + i * 120),
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double value, Widget? child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 14),
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.paper,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(999),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                step.chips[i],
                style: AppTextStyles.tinyMedium.copyWith(color: AppColors.ink),
              ),
            ),
          ),
        ),
      );
    }
    return chips;
  }
}

/// Carita mínima que le da un toque de personalidad al recorrido.
class _MascotaPainter extends CustomPainter {
  const _MascotaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centro = Offset(size.width / 2, size.height / 2);
    final Paint fondo = Paint()..color = AppColors.ink;
    canvas.drawCircle(centro, size.width / 2, fondo);

    final Paint blanco = Paint()..color = AppColors.paper;
    canvas.drawCircle(centro.translate(-6, -4), 2.6, blanco);
    canvas.drawCircle(centro.translate(6, -4), 2.6, blanco);

    final Paint sonrisa = Paint()
      ..color = AppColors.paper
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: centro.translate(0, 4), width: 14, height: 11),
      0.15,
      math.pi - 0.3,
      false,
      sonrisa,
    );
  }

  @override
  bool shouldRepaint(covariant _MascotaPainter oldDelegate) => false;
}
