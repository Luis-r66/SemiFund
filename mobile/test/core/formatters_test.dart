import 'package:flutter_test/flutter_test.dart';
import 'package:semi_fund/core/utils/formatters.dart';

void main() {
  test('formatea pesos colombianos sin decimales', () {
    expect(formatCop(480000), r'$480.000');
    expect(formatCop(0), r'$0');
    expect(formatCop(1250000), r'$1.250.000');
  });

  test('formatea el mes YYYY-MM en español', () {
    expect(formatMonth('2026-10'), 'Octubre 2026');
    expect(formatMonth('2026-01'), 'Enero 2026');
    expect(formatMonth(''), '—');
  });

  test('formatea fechas cortas', () {
    expect(formatShortDate(DateTime(2026, 9, 28)), '28 sep 2026');
  });

  test('extrae iniciales y primer nombre', () {
    expect(initials('Valentina Ríos'), 'VR');
    expect(initials('Luis'), 'L');
    expect(initials(''), '?');
    expect(initials('Luis Ernesto Ríos Pérez'), 'LR');
    expect(
      initialsFromParts(nombres: 'Luis Ernesto', apellidos: 'Ríos Pérez'),
      'LR',
    );
    expect(initialsFromParts(nombres: 'Luis', apellidos: 'Ríos'), 'LR');
    expect(firstName('Valentina Ríos'), 'Valentina');
  });

  test('construye la etiqueta de rol', () {
    expect(roleLabel(esTesorero: true, estado: 'activo'), 'Tesorero');
    expect(roleLabel(esTesorero: false, estado: 'activo'), 'Integrante');
    expect(roleLabel(esTesorero: true, estado: 'pendiente'), 'Pendiente');
  });
}
