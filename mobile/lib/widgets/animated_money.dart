import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';

/// Saldo que cuenta desde cero hasta el valor real. Si el saldo cambia,
/// anima desde el valor anterior en lugar de saltar.
class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  final double value;
  final TextStyle style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return Text(formatCop(value), style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double current, Widget? child) {
        return Text(formatCop(current), style: style);
      },
    );
  }
}
