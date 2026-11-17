import 'package:flutter_test/flutter_test.dart';
import 'package:semi_fund/models/balance.dart';
import 'package:semi_fund/models/semillero_detail.dart';
import 'package:semi_fund/models/semillero_membership.dart';

void main() {
  group('Balance', () {
    test('lee el saldo inicial y el disponible', () {
      final Balance balance = Balance.fromJson(<String, dynamic>{
        'saldoInicial': 200000,
        'totalAportado': 50000,
        'totalGastado': 30000,
        'saldoDisponible': 220000,
      });
      expect(balance.saldoInicial, 200000);
      expect(balance.saldoDisponible, 220000);
    });

    test('los semilleros anteriores sin saldo inicial se leen en cero', () {
      final Balance balance = Balance.fromJson(<String, dynamic>{
        'totalAportado': 10000,
        'totalGastado': 0,
        'saldoDisponible': 10000,
      });
      expect(balance.saldoInicial, 0);
    });
  });

  group('SemilleroMembership', () {
    test('lee saldo inicial, nota y permiso de ajuste', () {
      final SemilleroMembership membership = SemilleroMembership.fromJson(
        <String, dynamic>{
          'id': 'm1',
          'semilleroId': 's1',
          'semilleroNombre': 'Semillero',
          'esTesorero': true,
          'esCreador': true,
          'estado': 'activo',
          'miembros': 4,
          'saldoInicial': 150000,
          'saldoInicialNota': 'Cuenta de ahorros',
          'puedeAjustarSaldoInicial': true,
        },
      );
      expect(membership.saldoInicial, 150000);
      expect(membership.saldoInicialNota, 'Cuenta de ahorros');
      expect(membership.puedeAjustarSaldoInicial, isTrue);
    });

    test('sin permiso el integrante no puede ajustar', () {
      final SemilleroMembership membership = SemilleroMembership.fromJson(
        <String, dynamic>{
          'id': 'm2',
          'semilleroId': 's1',
          'semilleroNombre': 'Semillero',
          'estado': 'activo',
        },
      );
      expect(membership.puedeAjustarSaldoInicial, isFalse);
      expect(membership.saldoInicial, 0);
    });
  });

  group('SemilleroDetail', () {
    test('lee el saldo inicial del detalle', () {
      final SemilleroDetail detail = SemilleroDetail.fromJson(
        <String, dynamic>{
          'id': 's1',
          'nombre': 'Semillero',
          'creadoPor': 'u1',
          'esTesorero': true,
          'esCreador': true,
          'puedeAjustarSaldoInicial': true,
          'saldoInicial': <String, dynamic>{
            'monto': 80000,
            'nota': 'Saldo de apertura',
          },
        },
      );
      expect(detail.saldoInicial, 80000);
      expect(detail.saldoInicialNota, 'Saldo de apertura');
      expect(detail.puedeAjustarSaldoInicial, isTrue);
    });
  });
}
