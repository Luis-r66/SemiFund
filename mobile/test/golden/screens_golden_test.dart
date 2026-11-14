import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:semi_fund/app.dart';
import 'package:semi_fund/core/theme/app_theme.dart';
import 'package:semi_fund/models/balance.dart';
import 'package:semi_fund/models/home_summary.dart';
import 'package:semi_fund/models/semillero_membership.dart';
import 'package:semi_fund/models/user.dart';
import 'package:semi_fund/providers/home_provider.dart';
import 'package:semi_fund/providers/app_info_provider.dart';
import 'package:semi_fund/providers/session_provider.dart';
import 'package:semi_fund/screens/auth/change_password_screen.dart';
import 'package:semi_fund/screens/auth/forgot_password_screen.dart';
import 'package:semi_fund/screens/auth/login_screen.dart';
import 'package:semi_fund/screens/auth/register_screen.dart';
import 'package:semi_fund/screens/auth/welcome_screen.dart';
import 'package:semi_fund/screens/home/home_screen.dart';
import 'package:semi_fund/screens/onboarding/academic_profile_screen.dart';
import 'package:semi_fund/screens/profile/profile_screen.dart';
import 'package:semi_fund/screens/semilleros/create_semillero_screen.dart';
import 'package:semi_fund/screens/semilleros/join_semillero_screen.dart';
import 'package:semi_fund/screens/semilleros/pending_request_screen.dart';
import 'package:semi_fund/screens/semilleros/semilleros_screen.dart';
import 'package:semi_fund/services/auth_service.dart';
import 'package:semi_fund/services/dashboard_service.dart';
import 'package:semi_fund/services/semillero_service.dart';

import '../helpers/fakes.dart';

class MockAuthService extends Mock implements AuthService {}

class MockSemilleroService extends Mock implements SemilleroService {}

class MockDashboardService extends Mock implements DashboardService {}

void main() {
  const UserModel user = UserModel(
    id: 'user-1',
    nombre: 'Valentina Ríos',
    nombres: 'Valentina',
    apellidos: 'Ríos',
    email: 'valentina.rios@universidad.edu.co',
    tipoUsuario: UserType.estudiante,
    programa: 'Ingeniería de Sistemas',
    semestre: 7,
  );

  const SemilleroMembership activeMembership = SemilleroMembership(
    id: 'membership-1',
    semilleroId: 'semillero-1',
    nombre: 'Semillero de Desarrollo de Software',
    esTesorero: true,
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

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
  });

  setUp(() {
    auth = MockAuthService();
    semilleros = MockSemilleroService();
    dashboard = MockDashboardService();
    store = FakeSessionStore()..token = 'token-1';
  });

  Future<SessionProvider> authenticatedSession({
    List<SemilleroMembership> memberships = const <SemilleroMembership>[
      activeMembership,
    ],
    String? activeId,
  }) async {
    store.semilleroId = activeId;
    when(() => auth.me()).thenAnswer((_) async => user);
    when(() => semilleros.list()).thenAnswer((_) async => memberships);
    final SessionProvider session = SessionProvider(
      authService: auth,
      semilleroService: semilleros,
      store: store,
    );
    await session.bootstrap();
    return session;
  }

  SessionProvider unauthenticatedSession() {
    store.token = null;
    return SessionProvider(
      authService: auth,
      semilleroService: semilleros,
      store: store,
    );
  }

  Widget wrap(
    Widget screen, {
    required SessionProvider session,
    HomeProvider? home,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppInfoProvider>.value(
          value: AppInfoProvider(FakeAppUpdateGateway()),
        ),
        ChangeNotifierProvider<SessionProvider>.value(value: session),
        if (home != null)
          ChangeNotifierProvider<HomeProvider>.value(value: home),
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

  Future<void> golden(
    WidgetTester tester,
    Widget screen, {
    required SessionProvider session,
    HomeProvider? home,
    required String name,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(screen, session: session, home: home));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('welcome', (WidgetTester tester) async {
    await golden(
      tester,
      const WelcomeScreen(),
      session: unauthenticatedSession(),
      name: 'welcome',
    );
  });

  testWidgets('login', (WidgetTester tester) async {
    await golden(
      tester,
      const LoginScreen(),
      session: unauthenticatedSession(),
      name: 'login',
    );
  });

  testWidgets('register', (WidgetTester tester) async {
    await golden(
      tester,
      const RegisterScreen(),
      session: unauthenticatedSession(),
      name: 'register',
    );
  });

  testWidgets('onboarding', (WidgetTester tester) async {
    final SessionProvider session = await authenticatedSession();
    await golden(
      tester,
      const AcademicProfileScreen(),
      session: session,
      name: 'onboarding',
    );
  });

  testWidgets('forgot password', (WidgetTester tester) async {
    await golden(
      tester,
      const ForgotPasswordScreen(),
      session: unauthenticatedSession(),
      name: 'forgot_password',
    );
  });

  testWidgets('change password', (WidgetTester tester) async {
    final SessionProvider session = await authenticatedSession();
    await golden(
      tester,
      const ChangePasswordScreen(),
      session: session,
      name: 'change_password',
    );
  });
  testWidgets('semilleros', (WidgetTester tester) async {
    final SessionProvider session = await authenticatedSession(
      memberships: const <SemilleroMembership>[
        activeMembership,
        pendingMembership,
      ],
    );
    await golden(
      tester,
      const SemillerosScreen(),
      session: session,
      name: 'semilleros',
    );
  });

  testWidgets('create semillero', (WidgetTester tester) async {
    final SessionProvider session = await authenticatedSession();
    await golden(
      tester,
      const CreateSemilleroScreen(),
      session: session,
      name: 'create_semillero',
    );
  });

  testWidgets('join semillero', (WidgetTester tester) async {
    final SessionProvider session = await authenticatedSession();
    await golden(
      tester,
      const JoinSemilleroScreen(),
      session: session,
      name: 'join_semillero',
    );
  });

  testWidgets('pending', (WidgetTester tester) async {
    final SessionProvider session = await authenticatedSession(
      memberships: const <SemilleroMembership>[pendingMembership],
    );
    await golden(
      tester,
      const PendingRequestScreen(membership: pendingMembership),
      session: session,
      name: 'pending',
    );
  });

  testWidgets('profile', (WidgetTester tester) async {
    final SessionProvider session = await authenticatedSession();
    await golden(
      tester,
      const ProfileScreen(),
      session: session,
      name: 'profile',
    );
  });

  testWidgets('home', (WidgetTester tester) async {
    when(() => dashboard.summary()).thenAnswer(
      (_) async => const HomeSummary(
        balance: Balance(
          totalAportado: 1250000,
          totalGastado: 470000,
          saldoDisponible: 780000,
        ),
        activeMembers: 2,
        pendingContributions: 1,
        expensesCount: 1,
      ),
    );

    final SessionProvider session = await authenticatedSession();
    final HomeProvider home = HomeProvider(
      dashboard,
      now: () => DateTime(2026, 10, 4, 9, 41),
    );
    await golden(
      tester,
      const HomeScreen(),
      session: session,
      home: home,
      name: 'home',
    );
  });

  testWidgets('desktop welcome', (WidgetTester tester) async {
    await golden(
      tester,
      const WelcomeScreen(),
      session: unauthenticatedSession(),
      name: 'desktop_welcome',
      size: const Size(1100, 900),
    );
  });

  testWidgets('desktop login', (WidgetTester tester) async {
    await golden(
      tester,
      const LoginScreen(),
      session: unauthenticatedSession(),
      name: 'desktop_login',
      size: const Size(1100, 900),
    );
  });

  testWidgets('desktop home', (WidgetTester tester) async {
    when(() => dashboard.summary()).thenAnswer(
      (_) async => const HomeSummary(
        balance: Balance.empty,
        activeMembers: 0,
        pendingContributions: 0,
        expensesCount: 0,
      ),
    );

    final SessionProvider session = await authenticatedSession();
    final HomeProvider home = HomeProvider(
      dashboard,
      now: () => DateTime(2026, 10, 4, 9, 41),
    );
    await golden(
      tester,
      const HomeScreen(),
      session: session,
      home: home,
      name: 'desktop_home',
      size: const Size(1100, 900),
    );
  });

  testWidgets('desktop shell', (WidgetTester tester) async {
    when(() => dashboard.summary()).thenAnswer(
      (_) async => const HomeSummary(
        balance: Balance.empty,
        activeMembers: 0,
        pendingContributions: 0,
        expensesCount: 0,
      ),
    );

    final SessionProvider session = await authenticatedSession();
    final HomeProvider home = HomeProvider(
      dashboard,
      now: () => DateTime(2026, 10, 4, 9, 41),
    );

    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppInfoProvider>.value(
            value: AppInfoProvider(FakeAppUpdateGateway()),
          ),
          ChangeNotifierProvider<SessionProvider>.value(value: session),
          ChangeNotifierProvider<HomeProvider>.value(value: home),
        ],
        child: SemiFundApp(session: session),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/desktop_shell.png'),
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
