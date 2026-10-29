import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:semi_fund/app.dart';
import 'package:semi_fund/models/balance.dart';
import 'package:semi_fund/models/contribution.dart';
import 'package:semi_fund/models/expense.dart';
import 'package:semi_fund/models/member.dart';
import 'package:semi_fund/models/semillero_membership.dart';
import 'package:semi_fund/models/user.dart';
import 'package:semi_fund/providers/home_provider.dart';
import 'package:semi_fund/providers/session_provider.dart';
import 'package:semi_fund/screens/accounts/accounts_screen.dart';
import 'package:semi_fund/screens/auth/login_screen.dart';
import 'package:semi_fund/screens/auth/welcome_screen.dart';
import 'package:semi_fund/screens/home/home_screen.dart';
import 'package:semi_fund/screens/onboarding/academic_profile_screen.dart';
import 'package:semi_fund/screens/semilleros/semilleros_screen.dart';
import 'package:semi_fund/services/auth_service.dart';
import 'package:semi_fund/services/dashboard_service.dart';
import 'package:semi_fund/services/semillero_service.dart';

import 'helpers/fakes.dart';

class MockAuthService extends Mock implements AuthService {}

class MockSemilleroService extends Mock implements SemilleroService {}

class MockDashboardService extends Mock implements DashboardService {}

void main() {
  const UserModel user = UserModel(
    id: 'user-1',
    nombre: 'Valentina Ríos',
    nombres: 'Valentina',
    apellidos: 'Ríos',
    email: 'valentina@universidad.edu.co',
    tipoUsuario: UserType.estudiante,
    programa: 'Ingeniería de Sistemas',
    semestre: 7,
  );

  const SemilleroMembership activeMembership = SemilleroMembership(
    id: 'membership-1',
    semilleroId: 'semillero-1',
    nombre: 'Semillero de Software',
    esTesorero: true,
    estado: MembershipStatus.activo,
    miembros: 6,
  );

  const SemilleroMembership integranteMembership = SemilleroMembership(
    id: 'membership-3',
    semilleroId: 'semillero-3',
    nombre: 'Semillero de Software',
    esTesorero: false,
    estado: MembershipStatus.activo,
    miembros: 6,
  );

  const SemilleroMembership pendingMembership = SemilleroMembership(
    id: 'membership-2',
    semilleroId: 'semillero-2',
    nombre: 'Semillero de Ciberseguridad',
    esTesorero: false,
    estado: MembershipStatus.pendiente,
    miembros: 0,
  );

  late MockAuthService auth;
  late MockSemilleroService semilleros;
  late MockDashboardService dashboard;
  late FakeSessionStore store;

  setUp(() {
    auth = MockAuthService();
    semilleros = MockSemilleroService();
    dashboard = MockDashboardService();
    store = FakeSessionStore();

    when(() => dashboard.balance()).thenAnswer((_) async => Balance.empty);
    when(() => dashboard.members(activo: true))
        .thenAnswer((_) async => const <Member>[]);
    when(() => dashboard.contributions(status: ContributionStatus.pendiente))
        .thenAnswer((_) async => const <Contribution>[]);
    when(() => dashboard.expenses()).thenAnswer((_) async => const <Expense>[]);
  });

  SessionProvider buildSession() {
    return SessionProvider(
      authService: auth,
      semilleroService: semilleros,
      store: store,
    );
  }

  Widget app(SessionProvider session) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionProvider>.value(value: session),
        ChangeNotifierProvider<HomeProvider>(
          create: (_) => HomeProvider(dashboard),
        ),
      ],
      child: SemiFundApp(session: session),
    );
  }

  void setPhoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('sin token muestra bienvenida', (WidgetTester tester) async {
    setPhoneSize(tester);
    final SessionProvider session = buildSession();
    await session.bootstrap();

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('bienvenida navega a iniciar sesión', (
    WidgetTester tester,
  ) async {
    setPhoneSize(tester);
    final SessionProvider session = buildSession();
    await session.bootstrap();

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('con semillero activo entra al inicio', (
    WidgetTester tester,
  ) async {
    setPhoneSize(tester);
    store.token = 'token-1';
    when(() => auth.me()).thenAnswer((_) async => user);
    when(() => semilleros.list())
        .thenAnswer((_) async => <SemilleroMembership>[activeMembership]);

    final SessionProvider session = buildSession();
    await session.bootstrap();

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('sin semillero activo muestra mis semilleros', (
    WidgetTester tester,
  ) async {
    setPhoneSize(tester);
    store.token = 'token-1';
    when(() => auth.me()).thenAnswer((_) async => user);
    when(() => semilleros.list())
        .thenAnswer((_) async => <SemilleroMembership>[pendingMembership]);

    final SessionProvider session = buildSession();
    await session.bootstrap();

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(find.byType(SemillerosScreen), findsOneWidget);
  });

  testWidgets('sesión expirada redirige al login', (WidgetTester tester) async {
    setPhoneSize(tester);
    store.token = 'token-1';
    when(() => auth.me()).thenAnswer((_) async => user);
    when(() => semilleros.list())
        .thenAnswer((_) async => <SemilleroMembership>[activeMembership]);

    final SessionProvider session = buildSession();
    await session.bootstrap();

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    await session.expireSession();
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.textContaining('sesión expiró'), findsOneWidget);
  });

  testWidgets('perfil incompleto redirige al onboarding', (
    WidgetTester tester,
  ) async {
    setPhoneSize(tester);
    store.token = 'token-1';
    when(() => auth.me()).thenAnswer(
      (_) async => const UserModel(
        id: 'user-2',
        nombre: 'Nuevo Usuario',
        email: 'nuevo@universidad.edu.co',
      ),
    );
    when(() => semilleros.list())
        .thenAnswer((_) async => <SemilleroMembership>[]);

    final SessionProvider session = buildSession();
    await session.bootstrap();

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(find.byType(AcademicProfileScreen), findsOneWidget);
  });

  testWidgets('integrante no puede entrar a Cuentas', (
    WidgetTester tester,
  ) async {
    setPhoneSize(tester);
    store.token = 'token-1';
    when(() => auth.me()).thenAnswer((_) async => user);
    when(() => semilleros.list())
        .thenAnswer((_) async => <SemilleroMembership>[integranteMembership]);

    final SessionProvider session = buildSession();
    await session.bootstrap();

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    final BuildContext homeContext = tester.element(find.byType(HomeScreen));
    GoRouter.of(homeContext).go('/accounts');
    await tester.pumpAndSettle();

    expect(find.byType(AccountsScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
