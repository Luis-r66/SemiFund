import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:semi_fund/core/theme/app_theme.dart';
import 'package:semi_fund/models/balance.dart';
import 'package:semi_fund/models/contribution.dart';
import 'package:semi_fund/models/expense.dart';
import 'package:semi_fund/models/member.dart';
import 'package:semi_fund/models/membership_account.dart';
import 'package:semi_fund/models/semillero_detail.dart';
import 'package:semi_fund/models/semillero_membership.dart';
import 'package:semi_fund/models/user.dart';
import 'package:semi_fund/providers/accounts_provider.dart';
import 'package:semi_fund/providers/contributions_provider.dart';
import 'package:semi_fund/providers/expenses_provider.dart';
import 'package:semi_fund/providers/invitation_provider.dart';
import 'package:semi_fund/providers/members_provider.dart';
import 'package:semi_fund/providers/session_provider.dart';
import 'package:semi_fund/screens/accounts/accounts_screen.dart';
import 'package:semi_fund/screens/contributions/contribution_form_screen.dart';
import 'package:semi_fund/screens/contributions/contributions_screen.dart';
import 'package:semi_fund/screens/expenses/expense_form_screen.dart';
import 'package:semi_fund/screens/expenses/expenses_screen.dart';
import 'package:semi_fund/screens/invite/invite_screen.dart';
import 'package:semi_fund/screens/members/member_detail_screen.dart';
import 'package:semi_fund/screens/members/members_screen.dart';
import 'package:semi_fund/services/auth_service.dart';
import 'package:semi_fund/services/dashboard_service.dart';
import 'package:semi_fund/services/management_service.dart';
import 'package:semi_fund/services/semillero_service.dart';
import 'package:semi_fund/widgets/form_controls.dart';

import '../helpers/fakes.dart';

class MockAuthService extends Mock implements AuthService {}

class MockSemilleroService extends Mock implements SemilleroService {}

class MockDashboardService extends Mock implements DashboardService {}

class MockManagementService extends Mock implements ManagementService {}

void main() {
  const UserModel user = UserModel(
    id: 'user-1',
    nombre: 'Valentina Ríos',
    email: 'valentina.rios@universidad.edu.co',
  );

  const SemilleroMembership treasurerMembership = SemilleroMembership(
    id: 'membership-1',
    semilleroId: 'semillero-1',
    nombre: 'Semillero de Desarrollo de Software',
    esTesorero: true,
    estado: MembershipStatus.activo,
    miembros: 6,
  );

  const List<Member> members = <Member>[
    Member(
      id: 'm1',
      nombre: 'Valentina Ríos',
      programa: 'Ingeniería de Sistemas',
      semestre: 7,
      activo: true,
    ),
    Member(
      id: 'm2',
      nombre: 'Santiago Morales',
      programa: 'Ingeniería de Software',
      semestre: 5,
      activo: true,
    ),
    Member(
      id: 'm3',
      nombre: 'Andrés Gutiérrez',
      programa: 'Ingeniería de Sistemas',
      semestre: 9,
      activo: false,
    ),
  ];

  const SemilleroDetail detail = SemilleroDetail(
    id: 'semillero-1',
    nombre: 'Semillero de Desarrollo de Software',
    creadoPor: 'user-1',
    esTesorero: true,
    codigo: 'DSW7K2QX',
  );

  late MockAuthService auth;
  late MockSemilleroService semilleros;
  late MockDashboardService reads;
  late MockManagementService writes;
  late FakeSessionStore store;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
  });

  setUp(() {
    auth = MockAuthService();
    semilleros = MockSemilleroService();
    reads = MockDashboardService();
    writes = MockManagementService();
    store = FakeSessionStore()..token = 'token-1';

    when(() => auth.me()).thenAnswer((_) async => user);
    when(() => semilleros.list())
        .thenAnswer((_) async => <SemilleroMembership>[treasurerMembership]);
    when(() => semilleros.accounts()).thenAnswer(
      (_) async => const <MembershipAccount>[
        MembershipAccount(
          id: 'a1',
          esTesorero: false,
          estado: MembershipStatus.pendiente,
          usuario: UserModel(
            id: 'u2',
            nombre: 'Daniel Suárez',
            email: 'daniel.suarez@universidad.edu.co',
          ),
        ),
        MembershipAccount(
          id: 'a2',
          esTesorero: true,
          estado: MembershipStatus.activo,
          usuario: UserModel(
            id: 'user-1',
            nombre: 'Valentina Ríos',
            email: 'valentina.rios@universidad.edu.co',
          ),
        ),
        MembershipAccount(
          id: 'a3',
          esTesorero: false,
          estado: MembershipStatus.activo,
          usuario: UserModel(
            id: 'u3',
            nombre: 'Santiago Morales',
            email: 'santiago.morales@universidad.edu.co',
          ),
        ),
      ],
    );
    when(() => semilleros.detail()).thenAnswer((_) async => detail);

    when(() => reads.members()).thenAnswer((_) async => members);
    when(() => reads.member('m1')).thenAnswer((_) async => members.first);
    when(() => reads.contributions(memberId: 'm1')).thenAnswer(
      (_) async => const <Contribution>[
        Contribution(
          id: 'c1',
          integranteId: 'm1',
          monto: 30000,
          mes: '2026-10',
          concepto: 'Cuota',
          estado: ContributionStatus.pagado,
        ),
        Contribution(
          id: 'c2',
          integranteId: 'm1',
          monto: 30000,
          mes: '2026-09',
          concepto: 'Cuota',
          estado: ContributionStatus.pagado,
        ),
      ],
    );
    when(() => reads.contributions(status: any(named: 'status'))).thenAnswer(
      (_) async => const <Contribution>[
        Contribution(
          id: 'c3',
          integranteId: 'm1',
          monto: 30000,
          mes: '2026-10',
          concepto: 'Cuota',
          estado: ContributionStatus.pagado,
        ),
        Contribution(
          id: 'c4',
          integranteId: 'm2',
          monto: 30000,
          mes: '2026-10',
          concepto: 'Cuota',
          estado: ContributionStatus.pendiente,
        ),
        Contribution(
          id: 'c5',
          integranteId: 'm2',
          monto: 30000,
          mes: '2026-08',
          concepto: 'Cuota',
          estado: ContributionStatus.vencido,
        ),
      ],
    );
    when(() => reads.expenses()).thenAnswer(
      (_) async => <Expense>[
        Expense(
          id: 'e1',
          descripcion: 'Dominio y hosting del sitio',
          categoria: 'infraestructura',
          monto: 185000,
          fecha: DateTime(2026, 9, 28),
        ),
        Expense(
          id: 'e2',
          descripcion: 'Refrigerios hackathon interna',
          categoria: 'eventos',
          monto: 142000,
          fecha: DateTime(2026, 9, 20),
        ),
      ],
    );
    when(() => reads.balance()).thenAnswer(
      (_) async => const Balance(
        totalAportado: 1250000,
        totalGastado: 327000,
        saldoDisponible: 923000,
      ),
    );
  });

  Widget wrap(
    Widget screen,
    SessionProvider session,
    List<ChangeNotifierProvider<ChangeNotifier>> extra,
  ) {
    return MultiProvider(
      providers: [
        Provider<DashboardService>.value(value: reads),
        Provider<ManagementService>.value(value: writes),
        ChangeNotifierProvider<SessionProvider>.value(value: session),
        ...extra,
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('es', 'CO'),
        supportedLocales: const <Locale>[Locale('es', 'CO'), Locale('en')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: screen,
      ),
    );
  }

  Future<SessionProvider> session() async {
    final SessionProvider session = SessionProvider(
      authService: auth,
      semilleroService: semilleros,
      store: store,
    );
    await session.bootstrap();
    return session;
  }

  Future<void> golden(
    WidgetTester tester,
    Widget screen, {
    required String name,
    required List<ChangeNotifierProvider<ChangeNotifier>> extra,
    Future<void> Function(WidgetTester tester)? interact,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final SessionProvider s = await session();
    await tester.pumpWidget(wrap(screen, s, extra));
    await tester.pumpAndSettle();
    if (interact != null) {
      await interact(tester);
      await tester.pumpAndSettle();
    }

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('accounts', (WidgetTester tester) async {
    await golden(
      tester,
      const AccountsScreen(),
      name: 'accounts',
      extra: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<AccountsProvider>(
          create: (_) => AccountsProvider(semilleros),
        ),
      ],
    );
  });

  testWidgets('invite', (WidgetTester tester) async {
    await golden(
      tester,
      const InviteScreen(),
      name: 'invite',
      extra: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<InvitationProvider>(
          create: (_) => InvitationProvider(semilleros),
        ),
      ],
    );
  });

  testWidgets('members', (WidgetTester tester) async {
    await golden(
      tester,
      const MembersScreen(),
      name: 'members',
      extra: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<MembersProvider>(
          create: (_) => MembersProvider(reads, writes),
        ),
      ],
    );
  });

  testWidgets('member detail', (WidgetTester tester) async {
    await golden(
      tester,
      const MemberDetailScreen(memberId: 'm1'),
      name: 'member_detail',
      extra: const <ChangeNotifierProvider<ChangeNotifier>>[],
    );
  });

  testWidgets('contributions', (WidgetTester tester) async {
    await golden(
      tester,
      const ContributionsScreen(),
      name: 'contributions',
      extra: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<ContributionsProvider>(
          create: (_) => ContributionsProvider(reads, writes),
        ),
      ],
    );
  });

  testWidgets('contribution form', (WidgetTester tester) async {
    await golden(
      tester,
      const ContributionFormScreen(),
      name: 'contribution_form',
      extra: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<MembersProvider>(
          create: (_) => MembersProvider(reads, writes),
        ),
        ChangeNotifierProvider<ContributionsProvider>(
          create: (_) => ContributionsProvider(reads, writes),
        ),
      ],
    );
  });

  testWidgets('expenses', (WidgetTester tester) async {
    await golden(
      tester,
      const ExpensesScreen(),
      name: 'expenses',
      extra: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<ExpensesProvider>(
          create: (_) => ExpensesProvider(reads, writes),
        ),
      ],
    );
  });

  testWidgets('expense form over budget', (WidgetTester tester) async {
    await golden(
      tester,
      const ExpenseFormScreen(),
      name: 'expense_form',
      extra: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<ExpensesProvider>(
          create: (_) => ExpensesProvider(reads, writes),
        ),
      ],
      interact: (WidgetTester tester) async {
        final Finder money = find.descendant(
          of: find.byType(MoneyField),
          matching: find.byType(TextField),
        );
        await tester.enterText(money, '999999');
      },
    );
  });

  testWidgets('expense form other category', (WidgetTester tester) async {
    await golden(
      tester,
      const ExpenseFormScreen(),
      name: 'expense_other',
      extra: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<ExpensesProvider>(
          create: (_) => ExpensesProvider(reads, writes),
        ),
      ],
      interact: (WidgetTester tester) async {
        await tester.tap(find.byType(DropdownButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Otros').last);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).at(1), 'Transporte');
      },
    );
  });
}

Future<void> _loadFonts() async {
  final FontLoader instrument = FontLoader('Instrument Sans')
    ..addFont(rootBundle.load('assets/fonts/InstrumentSans.ttf'));
  await instrument.load();

  final FontLoader mono = FontLoader('Geist Mono')
    ..addFont(rootBundle.load('assets/fonts/GeistMono.ttf'));
  await mono.load();

  final FontLoader lucide = FontLoader('packages/lucide_icons_flutter/Lucide')
    ..addFont(
      rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
    );
  await lucide.load();
}
