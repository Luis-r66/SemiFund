import 'package:flutter_test/flutter_test.dart';
import 'package:semi_fund/models/balance.dart';
import 'package:semi_fund/models/contribution.dart';
import 'package:semi_fund/models/expense.dart';
import 'package:semi_fund/models/member.dart';
import 'package:semi_fund/models/semillero_membership.dart';
import 'package:semi_fund/models/user.dart';

void main() {
  test('parsea una membresía de semillero', () {
    final SemilleroMembership membership = SemilleroMembership.fromJson(
      <String, dynamic>{
        'id': 'membership-1',
        'semilleroId': 'semillero-1',
        'semilleroNombre': 'Semillero de Software',
        'semilleroCodigo': 'ABC12345',
        'esTesorero': true,
        'estado': 'activo',
        'miembros': 6,
      },
    );

    expect(membership.id, 'membership-1');
    expect(membership.semilleroId, 'semillero-1');
    expect(membership.nombre, 'Semillero de Software');
    expect(membership.codigo, 'ABC12345');
    expect(membership.esTesorero, isTrue);
    expect(membership.estado, MembershipStatus.activo);
    expect(membership.roleLabel, 'Tesorero');
    expect(membership.isActive, isTrue);
  });

  test('tolera respuestas de Mongoose con _id', () {
    final Member member = Member.fromJson(<String, dynamic>{
      '_id': 'member-1',
      'nombre': 'Ana Torres',
      'programa': 'Ingeniería de Software',
      'semestre': 5,
      'activo': true,
      'fechaIngreso': '2026-02-10T15:00:00.000Z',
      '__v': 0,
    });

    expect(member.id, 'member-1');
    expect(member.semestre, 5);
    expect(member.activo, isTrue);
    expect(member.fechaIngreso, isNotNull);
  });

  test('interpreta estados de aporte en español e inglés', () {
    final Contribution pending = Contribution.fromJson(<String, dynamic>{
      'id': 'c1',
      'integranteId': 'm1',
      'monto': 50000,
      'mes': '2026-09',
      'concepto': 'Cuota mensual',
      'estado': 'pendiente',
      'fechaPago': null,
    });
    final Contribution overdue = Contribution.fromJson(<String, dynamic>{
      'id': 'c2',
      'integranteId': 'm1',
      'monto': 50000,
      'mes': '2026-09',
      'estado': 'overdue',
    });

    expect(pending.estado, ContributionStatus.pendiente);
    expect(pending.concepto, 'Cuota mensual');
    expect(overdue.estado, ContributionStatus.vencido);
    expect(overdue.concepto, '');
  });

  test('parsea balance y gastos', () {
    final Balance balance = Balance.fromJson(<String, dynamic>{
      'totalAportado': 350000,
      'totalGastado': 120000,
      'saldoDisponible': 230000,
    });
    final Expense expense = Expense.fromJson(<String, dynamic>{
      'id': 'e1',
      'descripcion': 'Bus evento',
      'categoria': 'transporte',
      'monto': 20000,
      'fecha': '2026-09-12T10:00:00.000Z',
    });

    expect(balance.saldoDisponible, 230000);
    expect(expense.monto, 20000);
    expect(expense.categoriaLabel, 'Transporte');
  });
  test('parsea perfil académico y calcula iniciales', () {
    final UserModel user = UserModel.fromJson(<String, dynamic>{
      'id': 'user-1',
      'nombre': 'Luis Ernesto Ríos Pérez',
      'nombres': 'Luis Ernesto',
      'apellidos': 'Ríos Pérez',
      'email': 'luis@universidad.edu.co',
      'tipoUsuario': 'estudiante',
      'programa': 'Ingeniería de Sistemas',
      'semestre': 7,
    });

    expect(user.tipoUsuario, UserType.estudiante);
    expect(user.isProfileComplete, isTrue);
    expect(user.initials, 'LR');
  });

  test('detecta un perfil incompleto', () {
    final UserModel user = UserModel.fromJson(<String, dynamic>{
      'id': 'user-2',
      'nombre': 'Nuevo Usuario',
      'email': 'nuevo@universidad.edu.co',
    });

    expect(user.tipoUsuario, isNull);
    expect(user.isProfileComplete, isFalse);
  });

  test('miembro con nombres separados usa las iniciales correctas', () {
    final Member member = Member.fromJson(<String, dynamic>{
      'id': 'member-2',
      'nombre': 'Luis Ernesto Ríos Pérez',
      'nombres': 'Luis Ernesto',
      'apellidos': 'Ríos Pérez',
      'programa': 'Ingeniería de Sistemas',
      'semestre': 7,
      'activo': true,
    });

    expect(member.initials, 'LR');
  });
}
