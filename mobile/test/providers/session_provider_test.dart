import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:semi_fund/core/storage/session_storage.dart';
import 'package:semi_fund/models/auth_result.dart';
import 'package:semi_fund/models/requests/auth_requests.dart';
import 'package:semi_fund/models/semillero_membership.dart';
import 'package:semi_fund/models/user.dart';
import 'package:semi_fund/providers/session_provider.dart';
import 'package:semi_fund/services/auth_service.dart';
import 'package:semi_fund/services/semillero_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockSemilleroService extends Mock implements SemilleroService {}

class FakeSessionStore implements SessionStore {
  String? token;
  String? semilleroId;
  String? role;
  String? nombre;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> saveToken(String value) async => token = value;

  @override
  Future<void> clearToken() async => token = null;

  @override
  Future<String?> readSemilleroId() async => semilleroId;

  @override
  Future<String?> readRole() async => role;

  @override
  Future<String?> readSemilleroName() async => nombre;

  @override
  Future<void> saveActiveSemillero({
    required String id,
    required String role,
    required String nombre,
  }) async {
    semilleroId = id;
    this.role = role;
    this.nombre = nombre;
  }

  @override
  Future<void> clearActiveSemillero() async {
    semilleroId = null;
    role = null;
    nombre = null;
  }

  @override
  Future<void> clearAll() async {
    await clearToken();
    await clearActiveSemillero();
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(const LoginRequest(email: '', password: ''));
    registerFallbackValue(
      const UpdateProfileRequest(
        nombres: '',
        apellidos: '',
        tipoUsuario: UserType.estudiante,
        programa: '',
      ),
    );
    registerFallbackValue(
      const ChangePasswordRequest(currentPassword: '', newPassword: ''),
    );
  });

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

  const SemilleroMembership membership = SemilleroMembership(
    id: 'membership-1',
    semilleroId: 'semillero-1',
    nombre: 'Semillero de Software',
    esTesorero: true,
    estado: MembershipStatus.activo,
    miembros: 6,
  );

  late MockAuthService auth;
  late MockSemilleroService semilleros;
  late FakeSessionStore store;
  late SessionProvider session;

  setUp(() {
    auth = MockAuthService();
    semilleros = MockSemilleroService();
    store = FakeSessionStore();
    session = SessionProvider(
      authService: auth,
      semilleroService: semilleros,
      store: store,
    );
  });

  test('sin token inicia como no autenticado', () async {
    await session.bootstrap();

    expect(session.status, SessionStatus.unauthenticated);
    expect(session.isAuthenticated, isFalse);
    verifyNever(() => auth.me());
    verifyNever(() => semilleros.list());
  });

  test('restaura sesión y selecciona el único semillero activo', () async {
    store.token = 'token-1';
    when(() => auth.me()).thenAnswer((_) async => user);
    when(() => semilleros.list())
        .thenAnswer((_) async => <SemilleroMembership>[membership]);

    await session.bootstrap();

    expect(session.status, SessionStatus.authenticated);
    expect(session.user?.nombre, 'Valentina Ríos');
    expect(session.activeSemillero?.semilleroId, 'semillero-1');
    expect(store.semilleroId, 'semillero-1');
    expect(store.role, 'tesorero');
  });

  test('login guarda el token y carga los semilleros', () async {
    when(
      () => auth.login(any()),
    ).thenAnswer((_) async => const AuthResult(token: 'token-2', user: user));
    when(() => semilleros.list())
        .thenAnswer((_) async => <SemilleroMembership>[membership]);

    await session.login(
      email: 'valentina@universidad.edu.co',
      password: 'password123',
    );

    expect(session.status, SessionStatus.authenticated);
    expect(store.token, 'token-2');
    expect(session.activeSemillero?.semilleroId, 'semillero-1');
  });

  test('seleccionar semillero actualiza el header persistido', () async {
    when(() => semilleros.list())
        .thenAnswer((_) async => <SemilleroMembership>[membership]);

    await session.selectSemillero(membership);

    expect(session.activeSemillero?.semilleroId, 'semillero-1');
    expect(store.semilleroId, 'semillero-1');
    expect(store.role, 'tesorero');
    expect(store.nombre, 'Semillero de Software');
  });

  test('expirar sesión limpia token y semillero activo', () async {
    store.token = 'token-1';
    store.semilleroId = 'semillero-1';
    when(() => auth.me()).thenAnswer((_) async => user);
    when(() => semilleros.list())
        .thenAnswer((_) async => <SemilleroMembership>[membership]);

    await session.bootstrap();
    await session.expireSession();

    expect(session.status, SessionStatus.unauthenticated);
    expect(store.token, isNull);
    expect(store.semilleroId, isNull);
    expect(session.notice, contains('expiró'));
  });

  test('completar perfil actualiza el usuario', () async {
    const UserModel updated = UserModel(
      id: 'user-1',
      nombre: 'Valentina Ríos',
      nombres: 'Valentina',
      apellidos: 'Ríos',
      email: 'valentina@universidad.edu.co',
      tipoUsuario: UserType.estudiante,
      programa: 'Ingeniería de Sistemas',
      semestre: 7,
    );
    when(() => auth.updateProfile(any())).thenAnswer((_) async => updated);

    await session.completeProfile(
      nombres: 'Valentina',
      apellidos: 'Ríos',
      tipoUsuario: UserType.estudiante,
      programa: 'Ingeniería de Sistemas',
      semestre: 7,
    );

    expect(session.user?.isProfileComplete, isTrue);
    expect(session.user?.programa, 'Ingeniería de Sistemas');
  });

  test('cambiar contraseña guarda el token nuevo', () async {
    when(() => auth.changePassword(any())).thenAnswer((_) async => 'new-token');

    await session.changePassword(
      currentPassword: 'password123',
      newPassword: 'password456',
    );

    expect(store.token, 'new-token');
  });
}
