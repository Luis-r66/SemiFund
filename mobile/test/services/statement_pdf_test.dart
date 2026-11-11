import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:semi_fund/models/contribution.dart';
import 'package:semi_fund/models/member.dart';
import 'package:semi_fund/models/member_statement.dart';
import 'package:semi_fund/services/statement_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('genera un PDF válido con el resumen y las cuotas', () async {
    const Member member = Member(
      id: 'm1',
      nombre: 'Valentina Ríos',
      programa: 'Ingeniería de Sistemas',
      semestre: 7,
      activo: true,
    );
    final MemberStatement statement = MemberStatement(
      esperado: 60000,
      cobrado: 30000,
      saldo: 30000,
      vencido: 0,
      alDia: false,
      cuotas: <Contribution>[
        const Contribution(
          id: 'c1',
          integranteId: 'm1',
          monto: 30000,
          mes: '2026-09',
          concepto: 'Cuota mensual',
          estado: ContributionStatus.pagado,
          montoPagado: 30000,
        ),
        const Contribution(
          id: 'c2',
          integranteId: 'm1',
          monto: 30000,
          mes: '2026-10',
          concepto: 'Cuota mensual',
          estado: ContributionStatus.pendiente,
          montoPagado: 0,
        ),
      ],
    );

    final Uint8List bytes = await buildMemberStatementPdf(member, statement);

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('genera el PDF aunque el integrante no tenga cuotas', () async {
    const Member member = Member(
      id: 'm2',
      nombre: 'Carlos Pérez',
      programa: 'Ingeniería de Software',
      semestre: 3,
      activo: true,
    );
    const MemberStatement statement = MemberStatement(
      esperado: 0,
      cobrado: 0,
      saldo: 0,
      vencido: 0,
      alDia: true,
      cuotas: <Contribution>[],
    );

    final Uint8List bytes = await buildMemberStatementPdf(member, statement);

    expect(bytes.length, greaterThan(1000));
  });
}
