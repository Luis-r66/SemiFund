import 'package:flutter_test/flutter_test.dart';
import 'package:semi_fund/models/abono.dart';
import 'package:semi_fund/models/contribution.dart';

Contribution _aporte({
  String estado = 'pendiente',
  double monto = 30000,
  double? montoPagado,
  bool esPropio = false,
  List<Abono> abonos = const <Abono>[],
}) {
  return Contribution(
    id: 'c1',
    integranteId: 'm1',
    monto: monto,
    mes: '2026-11',
    concepto: 'Cuota',
    estado: ContributionStatus.fromApi(estado),
    esPropio: esPropio,
    montoPagado: montoPagado,
    abonos: abonos,
  );
}

void main() {
  test('parsea abonos del backend con su estado y datos', () {
    final Contribution item = Contribution.fromJson(<String, dynamic>{
      'id': 'c1',
      'integranteId': 'm1',
      'monto': 30000,
      'mes': '2026-11',
      'concepto': 'Cuota',
      'estado': 'reportado',
      'montoPagado': 0,
      'abonos': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'a1',
          'monto': 15000,
          'estado': 'reportado',
          'fecha': '2026-11-10T10:00:00.000Z',
          'referencia': 'TRX-9',
        },
      ],
    });

    expect(item.abonos, hasLength(1));
    expect(item.abonos.first.id, 'a1');
    expect(item.abonos.first.estado, AbonoStatus.reportado);
    expect(item.abonos.first.referencia, 'TRX-9');
    expect(item.hasAbonoReportado, isTrue);
  });

  test('abono aprobado parcial: cobrado, saldo y parcial', () {
    final Contribution item = _aporte(
      montoPagado: 15000,
      abonos: const <Abono>[
        Abono(id: 'a1', monto: 15000, estado: AbonoStatus.aprobado),
      ],
    );

    expect(item.cobrado, 15000);
    expect(item.saldoPendiente, 15000);
    expect(item.isParcial, isTrue);
    expect(item.isPaid, isFalse);
  });

  test('un aporte pagado sin montoPagado cuenta completo (datos antiguos)', () {
    final Contribution item = _aporte(estado: 'pagado');

    expect(item.cobrado, 30000);
    expect(item.saldoPendiente, 0);
    expect(item.isParcial, isFalse);
  });

  test('el saldo nunca es negativo', () {
    final Contribution item = _aporte(montoPagado: 40000);

    expect(item.saldoPendiente, 0);
  });

  test('no se puede reportar mientras hay un abono esperando revisión', () {
    final Contribution conAbono = _aporte(
      esPropio: true,
      abonos: const <Abono>[
        Abono(id: 'a1', monto: 10000, estado: AbonoStatus.reportado),
      ],
    );
    final Contribution libre = _aporte(esPropio: true);

    expect(conAbono.canReport, isFalse);
    expect(libre.canReport, isTrue);
  });

  test('un integrante puede reportar la parte que falta de una cuota parcial', () {
    final Contribution item = _aporte(
      esPropio: true,
      montoPagado: 15000,
      abonos: const <Abono>[
        Abono(id: 'a1', monto: 15000, estado: AbonoStatus.aprobado),
      ],
    );

    expect(item.canReport, isTrue);
  });

  test('estado de abono desconocido cae en reportado', () {
    expect(AbonoStatus.fromApi('algo raro'), AbonoStatus.reportado);
    expect(AbonoStatus.fromApi('Aprobado'), AbonoStatus.aprobado);
  });
}
