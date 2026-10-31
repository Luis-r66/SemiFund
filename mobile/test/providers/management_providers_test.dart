import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:semi_fund/core/network/api_exception.dart';
import 'package:semi_fund/core/utils/formatters.dart';
import 'package:semi_fund/models/balance.dart';
import 'package:semi_fund/models/contribution.dart';
import 'package:semi_fund/models/expense.dart';
import 'package:semi_fund/models/member.dart';
import 'package:semi_fund/models/membership_account.dart';
import 'package:semi_fund/models/semillero_membership.dart';
import 'package:semi_fund/models/user.dart';
import 'package:semi_fund/providers/accounts_provider.dart';
import 'package:semi_fund/providers/contributions_provider.dart';
import 'package:semi_fund/providers/expenses_provider.dart';
import 'package:semi_fund/providers/members_provider.dart';
import 'package:semi_fund/services/dashboard_service.dart';
import 'package:semi_fund/services/management_service.dart';
import 'package:semi_fund/services/semillero_service.dart';

class MockSemilleroService extends Mock implements SemilleroService {}

class MockDashboardService extends Mock implements DashboardService {}

class MockManagementService extends Mock implements ManagementService {}

void main() {
  group('formatters', () {
    test('parseMoney ignora separadores', () {
      expect(parseMoney('520.000'), 520000);
      expect(parseMoney(''), 0);
    });

    test('formatThousands usa punto como separador de miles', () {
      expect(formatThousands(1250000), '1.250.000');
    });

    test('monthOptions incluye el mes actual en formato YYYY-MM', () {
      final List<String> months = monthOptions(
        DateTime(2026, 10, 15),
        back: 2,
        forward: 1,
      );
      expect(months, <String>['2026-08', '2026-09', '2026-10', '2026-11']);
    });

    test('monthOptions cruza el cambio de año', () {
      final List<String> months = monthOptions(
        DateTime(2026, 1, 5),
        back: 1,
        forward: 1,
      );
      expect(months, <String>['2025-12', '2026-01', '2026-02']);
    });

    test('formatInviteCode agrupa en dos bloques de cuatro', () {
      expect(formatInviteCode('DSW7K2QX'), 'DSW7 · K2QX');
    });

    test('relativeDays describe antigüedad', () {
      final DateTime now = DateTime(2026, 10, 27, 12);
      expect(relativeDays(DateTime(2026, 10, 27, 8), now: now), 'Hoy');
      expect(relativeDays(DateTime(2026, 10, 26, 8), now: now), 'Ayer');
      expect(relativeDays(DateTime(2026, 10, 25, 8), now: now), 'Hace 2 días');
    });
  });

  group('AccountsProvider', () {
    late MockSemilleroService service;
    late AccountsProvider provider;

    const MembershipAccount pending = MembershipAccount(
      id: 'm-pending',
      esTesorero: false,
      estado: MembershipStatus.pendiente,
      usuario: UserModel(
        id: 'u2',
        nombre: 'Daniel Suárez',
        email: 'daniel@u.edu.co',
      ),
    );

    const MembershipAccount treasurer = MembershipAccount(
      id: 'm-tes',
      esTesorero: true,
      estado: MembershipStatus.activo,
      usuario: UserModel(
        id: 'u1',
        nombre: 'Valentina Ríos',
        email: 'val@u.edu.co',
      ),
    );

    setUp(() {
      service = MockSemilleroService();
      provider = AccountsProvider(service);
      when(() => service.accounts())
          .thenAnswer((_) async => <MembershipAccount>[pending, treasurer]);
    });

    test('separa solicitudes pendientes de integrantes con cuenta', () async {
      await provider.load();
      expect(provider.pending.map((MembershipAccount a) => a.id), <String>[
        'm-pending',
      ]);
      expect(provider.members.map((MembershipAccount a) => a.id), <String>[
        'm-tes',
      ]);
      expect(provider.activeTreasurers, 1);
    });

    test('aprobar envía estado activo y recarga', () async {
      when(() => service.updateAccount(any(), estado: any(named: 'estado')))
          .thenAnswer((_) async {});
      await provider.load();
      await provider.approve(pending);
      verify(
        () =>
            service.updateAccount('m-pending', estado: MembershipStatus.activo),
      ).called(1);
      verify(() => service.accounts()).called(2);
    });

    test('error del backend se expone al usuario', () async {
      when(
        () =>
            service.updateAccount(any(), esTesorero: any(named: 'esTesorero')),
      ).thenThrow(
        const ApiException(
          kind: ApiErrorKind.conflict,
          statusCode: 409,
          message:
              'No se puede quitar el rol de tesorero: debe quedar al menos uno',
        ),
      );
      await expectLater(
        provider.setTreasurer(treasurer, value: false),
        throwsA(isA<ApiException>()),
      );
      expect(provider.error, contains('al menos uno'));
    });
  });

  group('MembersProvider', () {
    late MockDashboardService reads;
    late MockManagementService writes;
    late MembersProvider provider;

    const Member ana = Member(
      id: 'm1',
      nombre: 'Ana Torres',
      programa: 'Ingeniería de Software',
      semestre: 5,
      activo: true,
    );

    setUp(() {
      reads = MockDashboardService();
      writes = MockManagementService();
      provider = MembersProvider(reads, writes);
      when(() => reads.members()).thenAnswer((_) async => <Member>[ana]);
    });

    test('reactivar envía solo activo en la allowlist', () async {
      when(() => writes.updateMember(any(), any()))
          .thenAnswer((_) async => ana);
      await provider.reactivate('m1');
      verify(() => writes.updateMember('m1', <String, dynamic>{'activo': true}))
          .called(1);
    });

    test('desactivar llama al endpoint de baja lógica', () async {
      when(() => writes.deactivateMember(any())).thenAnswer((_) async {});
      await provider.deactivate('m1');
      verify(() => writes.deactivateMember('m1')).called(1);
    });

    test('activeMembers excluye inactivos', () async {
      when(() => reads.members()).thenAnswer(
        (_) async => <Member>[
          ana,
          const Member(
            id: 'm2',
            nombre: 'Luis',
            programa: 'Sistemas',
            semestre: 3,
            activo: false,
          ),
        ],
      );
      await provider.load();
      expect(provider.members, hasLength(2));
      expect(provider.activeMembers.map((Member m) => m.id), <String>['m1']);
    });
  });

  group('ContributionsProvider', () {
    late MockDashboardService reads;
    late MockManagementService writes;
    late ContributionsProvider provider;

    final Contribution pendingItem = Contribution.fromJson(<String, dynamic>{
      'id': 'c1',
      'integranteId': 'm1',
      'monto': 30000,
      'mes': '2026-10',
      'concepto': 'Cuota',
      'estado': 'pendiente',
    });

    setUp(() {
      reads = MockDashboardService();
      writes = MockManagementService();
      provider = ContributionsProvider(reads, writes);
      when(() => reads.contributions(status: any(named: 'status')))
          .thenAnswer((_) async => <Contribution>[pendingItem]);
      when(() => reads.members()).thenAnswer(
        (_) async => <Member>[
          const Member(
            id: 'm1',
            nombre: 'Ana Torres',
            programa: 'Software',
            semestre: 5,
            activo: true,
          ),
        ],
      );
    });

    test('resuelve el nombre del integrante desde la lista', () async {
      await provider.load();
      expect(provider.memberName('m1'), 'Ana Torres');
      expect(provider.memberName('desconocido'), 'Integrante no disponible');
    });

    test('pagar llama al endpoint y recarga con el filtro actual', () async {
      when(() => writes.payContribution(any()))
          .thenAnswer((_) async => pendingItem);
      await provider.load(status: ContributionStatus.pendiente);
      await provider.pay(pendingItem);
      verify(() => writes.payContribution('c1')).called(1);
      verify(() => reads.contributions(status: ContributionStatus.pendiente))
          .called(2);
    });

    test('reportar y rechazar llaman al endpoint y recargan', () async {
      when(() => writes.reportContribution(any(), referencia: any(named: 'referencia')))
          .thenAnswer((_) async => pendingItem);
      when(() => writes.rejectContribution(any(), motivo: any(named: 'motivo')))
          .thenAnswer((_) async => pendingItem);
      await provider.load();
      await provider.report(pendingItem, referencia: 'TRX-1');
      await provider.reject(pendingItem, motivo: 'Revisar');
      verify(() => writes.reportContribution('c1', referencia: 'TRX-1')).called(1);
      verify(() => writes.rejectContribution('c1', motivo: 'Revisar')).called(1);
    });
  });

  group('ExpensesProvider', () {
    late MockDashboardService reads;
    late MockManagementService writes;
    late ExpensesProvider provider;

    setUp(() {
      reads = MockDashboardService();
      writes = MockManagementService();
      provider = ExpensesProvider(reads, writes);
      when(() => reads.expenses()).thenAnswer(
        (_) async => <Expense>[
          const Expense(
            id: 'e1',
            descripcion: 'Hosting',
            categoria: 'infraestructura',
            monto: 185000,
          ),
        ],
      );
      when(() => reads.balance()).thenAnswer(
        (_) async => const Balance(
          totalAportado: 480000,
          totalGastado: 185000,
          saldoDisponible: 295000,
        ),
      );
    });

    test('carga gastos y saldo real', () async {
      await provider.load();
      expect(provider.expenses, hasLength(1));
      expect(provider.balance.saldoDisponible, 295000);
      expect(provider.expenses.first.categoriaLabel, 'Infraestructura');
    });

    test('propaga el 409 de saldo insuficiente', () async {
      when(
        () => writes.createExpense(
          descripcion: any(named: 'descripcion'),
          categoria: any(named: 'categoria'),
          monto: any(named: 'monto'),
        ),
      ).thenThrow(
        const ApiException(
          kind: ApiErrorKind.conflict,
          statusCode: 409,
          message: 'Saldo insuficiente',
        ),
      );
      await expectLater(
        provider.create(
          descripcion: 'Camisetas',
          categoria: 'otros',
          monto: 999999,
        ),
        throwsA(predicate((Object e) => e is ApiException && e.isConflict)),
      );
    });
  });
}
