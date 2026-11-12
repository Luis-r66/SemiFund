import 'package:flutter/material.dart';
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
import 'package:semi_fund/screens/auth/login_screen.dart';
import 'package:semi_fund/screens/auth/welcome_screen.dart';
import 'package:semi_fund/screens/home/home_screen.dart';
import 'package:semi_fund/services/auth_service.dart';
import 'package:semi_fund/services/dashboard_service.dart';
import 'package:semi_fund/services/semillero_service.dart';
import 'package:semi_fund/widgets/auth_brand_panel.dart';

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
    when(() => dashboard.contributions())
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

  void setDesktopSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  void authenticate() {
    store.token = 'token-1';
    when(() => auth.me()).thenAnswer((_) async => user);
    when(() => semilleros.list())
        .thenAnswer((_) async => <SemilleroMembership>[activeMembership]);
  }

  testWidgets('la bienvenida ocupa el ancho de escritorio', (
    WidgetTester tester,
  ) async {
    setDesktopSize(tester);
    final SessionProvider session = buildSession();
    await session.bootstrap();

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el login muestra el panel de marca en escritorio', (
    WidgetTester tester,
  ) async {
    setDesktopSize(tester);
    final SessionProvider session = buildSession();
    await session.bootstrap();

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(AuthBrandPanel), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el inicio muestra la barra lateral y el tablero en escritorio', (
    WidgetTester tester,
  ) async {
    setDesktopSize(tester);
    authenticate();
    final SessionProvider session = buildSession();
    await session.bootstrap();

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('desktop-sidebar')),
      findsOneWidget,
    );
    expect(find.text('Integrantes'), findsOneWidget);
    expect(find.text('Aportes'), findsOneWidget);
    expect(find.text('Gastos'), findsOneWidget);
    expect(find.text('Cuentas'), findsOneWidget);
    expect(find.text('RESUMEN'), findsOneWidget);
    expect(find.text('GESTIONAR'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
