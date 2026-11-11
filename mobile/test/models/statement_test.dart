import 'package:flutter_test/flutter_test.dart';
import 'package:semi_fund/models/audit_entry.dart';
import 'package:semi_fund/models/member_statement.dart';

void main() {
  test('parsea el estado de cuenta con su resumen y cuotas', () {
    final MemberStatement statement = MemberStatement.fromJson(
      <String, dynamic>{
        'resumen': <String, dynamic>{
          'esperado': 90000,
          'cobrado': 60000,
          'saldo': 30000,
          'vencido': 30000,
        },
        'alDia': false,
        'cuotas': <dynamic>[
          <String, dynamic>{
            'id': 'c1',
            'integranteId': 'm1',
            'monto': 30000,
            'mes': '2026-08',
            'estado': 'vencido',
            'montoPagado': 0,
          },
          <String, dynamic>{
            'id': 'c2',
            'integranteId': 'm1',
            'monto': 30000,
            'mes': '2026-09',
            'estado': 'pagado',
            'montoPagado': 30000,
          },
        ],
      },
    );

    expect(statement.esperado, 90000);
    expect(statement.cobrado, 60000);
    expect(statement.saldo, 30000);
    expect(statement.vencido, 30000);
    expect(statement.alDia, isFalse);
    expect(statement.cuotas, hasLength(2));
    expect(statement.cuotas.first.mes, '2026-08');
  });

  test('estado de cuenta sin cuotas queda al día', () {
    final MemberStatement statement = MemberStatement.fromJson(
      <String, dynamic>{'resumen': <String, dynamic>{}, 'alDia': true},
    );

    expect(statement.esperado, 0);
    expect(statement.saldo, 0);
    expect(statement.cuotas, isEmpty);
    expect(statement.alDia, isTrue);
  });

  test('auditoría usa el nombre del usuario y un título legible', () {
    final AuditEntry entry = AuditEntry.fromJson(<String, dynamic>{
      'id': 'a1',
      'accion': 'aporte.cuotas_masivas',
      'entidad': 'aporte',
      'detalle': '2026-10 · 5 creadas · 30000',
      'creadoEn': '2026-10-04T15:30:00.000Z',
      'usuarioId': <String, dynamic>{
        'nombres': 'Valentina',
        'apellidos': 'Ríos',
      },
    });

    expect(entry.titulo, 'Cuotas del mes creadas');
    expect(entry.usuario, 'Valentina Ríos');
    expect(entry.detalle, contains('5 creadas'));
    expect(entry.creadoEn, isNotNull);
  });

  test('auditoría tolera acciones y usuarios desconocidos', () {
    final AuditEntry entry = AuditEntry.fromJson(<String, dynamic>{
      'accion': 'accion.nueva',
      'usuarioId': <String, dynamic>{'email': 'tesorero@udea.edu.co'},
    });

    expect(entry.titulo, 'accion.nueva');
    expect(entry.usuario, 'tesorero@udea.edu.co');
    expect(entry.creadoEn, isNull);
  });
}
