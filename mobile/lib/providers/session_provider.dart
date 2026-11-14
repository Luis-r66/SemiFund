import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../core/storage/session_storage.dart';
import '../models/auth_result.dart';
import '../models/join_result.dart';
import '../models/requests/auth_requests.dart';
import '../models/semillero_detail.dart';
import '../models/semillero_membership.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/semillero_service.dart';
import '../services/tutorial_service.dart';

enum SessionStatus { bootstrapping, unauthenticated, authenticated }

class SessionProvider extends ChangeNotifier {
  SessionProvider({
    required AuthService authService,
    required SemilleroService semilleroService,
    required SessionStore store,
    TutorialStore? tutorialStore,
  }) : _authService = authService,
       _semilleroService = semilleroService,
       _store = store,
       _tutorialStore = tutorialStore;

  final AuthService _authService;
  final SemilleroService _semilleroService;
  final SessionStore _store;
  final TutorialStore? _tutorialStore;

  SessionStatus _status = SessionStatus.bootstrapping;
  UserModel? _user;
  List<SemilleroMembership> _semilleros = <SemilleroMembership>[];
  SemilleroMembership? _activeSemillero;
  String? _notice;
  String? _bootstrapError;
  bool _isBusy = false;
  bool _booting = false;
  bool _expiring = false;
  bool _descartandoEliminado = false;
  bool _tutorialPendiente = false;

  SessionStatus get status => _status;
  UserModel? get user => _user;
  List<SemilleroMembership> get semilleros => List.unmodifiable(_semilleros);
  SemilleroMembership? get activeSemillero => _activeSemillero;
  String? get notice => _notice;
  String? get bootstrapError => _bootstrapError;
  bool get isBusy => _isBusy;

  /// La cuenta completó sus datos y todavía no ha visto el recorrido inicial.
  bool get tutorialPendiente => _tutorialPendiente;

  bool get isAuthenticated => _status == SessionStatus.authenticated;
  bool get hasActiveSemillero => _activeSemillero != null;
  bool get isTesorero => _activeSemillero?.esTesorero ?? false;

  List<SemilleroMembership> get activeMemberships =>
      _semilleros.where((SemilleroMembership item) => item.isActive).toList();

  Future<void> bootstrap() async {
    if (_booting) return;
    _booting = true;
    _status = SessionStatus.bootstrapping;
    _bootstrapError = null;
    notifyListeners();

    try {
      final String? token = await _store.readToken();
      if (token == null || token.isEmpty) {
        _status = SessionStatus.unauthenticated;
        return;
      }

      final List<dynamic> results = await Future.wait<dynamic>(
        <Future<dynamic>>[_authService.me(), _semilleroService.list()],
      );

      _user = results[0] as UserModel;
      _semilleros = results[1] as List<SemilleroMembership>;
      await _resolveActiveSemillero();
      await _actualizarTutorial();
      _status = SessionStatus.authenticated;
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        await _clearLocalSession();
        _status = SessionStatus.unauthenticated;
        _notice = 'Tu sesión expiró. Inicia sesión de nuevo.';
      } else {
        _bootstrapError = error.message;
      }
    } catch (_) {
      _bootstrapError = 'No se pudo iniciar la aplicación. Intenta de nuevo.';
    } finally {
      _booting = false;
      notifyListeners();
    }
  }

  Future<void> retryBootstrap() => bootstrap();

  Future<void> login({required String email, required String password}) async {
    _isBusy = true;
    _notice = null;
    notifyListeners();

    try {
      final AuthResult result = await _authService.login(
        LoginRequest(email: email.trim(), password: password),
      );
      await _store.saveToken(result.token);
      _user = result.user;
      _status = SessionStatus.authenticated;
      await _actualizarTutorial();
      await _reloadSemillerosSafely();
    } on ApiException catch (error) {
      _notice = error.message;
      rethrow;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  bool get isProfileComplete => _user?.isProfileComplete ?? false;

  Future<void> loginWithGoogle(String idToken) async {
    _isBusy = true;
    _notice = null;
    notifyListeners();

    try {
      final AuthResult result = await _authService.loginWithGoogle(idToken);
      await _store.saveToken(result.token);
      _user = result.user;
      _status = SessionStatus.authenticated;
      await _actualizarTutorial();
      await _reloadSemillerosSafely();
    } on ApiException catch (error) {
      _notice = error.message;
      rethrow;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String nombres,
    required String apellidos,
    required String email,
    required String password,
  }) async {
    _isBusy = true;
    _notice = null;
    notifyListeners();

    try {
      final AuthResult result = await _authService.register(
        RegisterRequest(
          nombres: nombres.trim(),
          apellidos: apellidos.trim(),
          email: email.trim(),
          password: password,
        ),
      );
      await _store.saveToken(result.token);
      _user = result.user;
      _status = SessionStatus.authenticated;
      await _actualizarTutorial();
      await _reloadSemillerosSafely();
    } on ApiException catch (error) {
      _notice = error.message;
      rethrow;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isBusy = true;
    notifyListeners();
    try {
      await _authService.logout();
    } catch (_) {
      // El cierre local debe ocurrir incluso si el servidor no responde.
    } finally {
      await _clearLocalSession();
      _notice = null;
      _status = SessionStatus.unauthenticated;
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> expireSession() async {
    if (_expiring || _status != SessionStatus.authenticated) return;
    _expiring = true;
    await _clearLocalSession();
    _status = SessionStatus.unauthenticated;
    _notice = 'Tu sesión expiró. Inicia sesión de nuevo.';
    _expiring = false;
    notifyListeners();
  }

  Future<void> refreshSemilleros() async {
    if (!isAuthenticated) return;
    await _reloadSemillerosSafely();
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    if (!isAuthenticated) return;
    try {
      _user = await _authService.me();
      notifyListeners();
    } on ApiException {
      // El interceptor global maneja la sesión expirada.
    }
  }

  Future<void> completeProfile({
    required String nombres,
    required String apellidos,
    required UserType tipoUsuario,
    required String programa,
    int? semestre,
  }) async {
    final UserModel updated = await _authService.updateProfile(
      UpdateProfileRequest(
        nombres: nombres.trim(),
        apellidos: apellidos.trim(),
        tipoUsuario: tipoUsuario,
        programa: programa.trim(),
        semestre: tipoUsuario == UserType.estudiante ? semestre : null,
      ),
    );
    _user = updated;
    await _actualizarTutorial();
    notifyListeners();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final String token = await _authService.changePassword(
      ChangePasswordRequest(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );
    if (token.isNotEmpty) await _store.saveToken(token);
    notifyListeners();
  }

  Future<void> forgotPassword(String email) =>
      _authService.forgotPassword(email.trim());

  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) => _authService.resetPassword(
    ResetPasswordRequest(
      email: email.trim(),
      code: code.trim(),
      password: password,
    ),
  );

  Future<SemilleroDetail> createSemillero(String nombre) async {
    final SemilleroDetail created = await _semilleroService.create(nombre);
    await _reloadSemillerosSafely();

    final SemilleroMembership? createdMembership = _findBySemilleroId(
      created.id,
    );
    if (createdMembership != null && createdMembership.isActive) {
      await selectSemillero(createdMembership);
    }
    return created;
  }

  Future<JoinSemilleroResult> joinSemillero(String codigo) async {
    final JoinSemilleroResult result = await _semilleroService.join(codigo);
    await _reloadSemillerosSafely();
    return result;
  }

  /// Sale del semillero activo sin borrarlo.
  Future<void> salirDelSemillero() async {
    await _semilleroService.salir();
    await _descartarSemilleroActivo();
  }

  /// Elimina el semillero activo. La API exige que sea el creador y que la
  /// confirmación coincida con el nombre.
  Future<void> eliminarSemillero({required String confirmacion}) async {
    await _semilleroService.eliminar(confirmacion);
    await _descartarSemilleroActivo();
  }

  /// Lo llama el cliente HTTP cuando otra cuenta eliminó el semillero activo.
  /// Suelta la sesión local y deja un aviso en "Mis semilleros".
  Future<void> descartarSemilleroEliminado() async {
    if (_descartandoEliminado || _activeSemillero == null) return;
    _descartandoEliminado = true;
    try {
      _notice = 'Este semillero fue eliminado por su creador.';
      await _descartarSemilleroActivo();
    } finally {
      _descartandoEliminado = false;
    }
  }

  Future<void> _descartarSemilleroActivo() async {
    final String? semilleroId = _activeSemillero?.semilleroId;
    _activeSemillero = null;
    if (semilleroId != null) {
      _semilleros = _semilleros
          .where((SemilleroMembership item) => item.semilleroId != semilleroId)
          .toList();
    }
    await _store.clearActiveSemillero();
    notifyListeners();

    // La lista local ya quedó consistente; si la red falla, se reintenta en
    // la próxima visita a "Mis semilleros" sin borrar lo que el usuario tiene.
    try {
      _semilleros = await _semilleroService.list();
      await _resolveActiveSemillero();
    } on ApiException {
      // Sin conexión: se conserva la lista local.
    }
    notifyListeners();
  }

  Future<void> selectSemillero(SemilleroMembership membership) async {
    if (!membership.isActive) {
      throw const ApiException(
        kind: ApiErrorKind.forbidden,
        message: 'Este semillero aún no está activo.',
      );
    }
    _activeSemillero = membership;
    await _store.saveActiveSemillero(
      id: membership.semilleroId,
      role: membership.esTesorero ? 'tesorero' : 'integrante',
      nombre: membership.nombre,
    );
    notifyListeners();
  }

  Future<void> clearActiveSemillero() async {
    _activeSemillero = null;
    await _store.clearActiveSemillero();
    notifyListeners();
  }

  void clearNotice() {
    if (_notice == null) return;
    _notice = null;
    notifyListeners();
  }

  SemilleroMembership? membershipFor(String semilleroId) =>
      _findBySemilleroId(semilleroId);

  SemilleroMembership? _findBySemilleroId(String semilleroId) {
    for (final SemilleroMembership membership in _semilleros) {
      if (membership.semilleroId == semilleroId) return membership;
    }
    return null;
  }

  Future<void> _reloadSemillerosSafely() async {
    try {
      _semilleros = await _semilleroService.list();
      await _resolveActiveSemillero();
    } on ApiException catch (error) {
      _semilleros = <SemilleroMembership>[];
      _activeSemillero = null;
      await _store.clearActiveSemillero();
      _notice = error.message;
    }
  }

  Future<void> _resolveActiveSemillero() async {
    final String? storedId = await _store.readSemilleroId();
    final List<SemilleroMembership> active = _semilleros
        .where((SemilleroMembership membership) => membership.isActive)
        .toList();

    SemilleroMembership? resolved;
    if (storedId != null && storedId.isNotEmpty) {
      for (final SemilleroMembership membership in active) {
        if (membership.semilleroId == storedId) {
          resolved = membership;
          break;
        }
      }
    }
    if (resolved == null && active.length == 1) {
      resolved = active.first;
    }

    _activeSemillero = resolved;
    if (resolved != null) {
      await _store.saveActiveSemillero(
        id: resolved.semilleroId,
        role: resolved.esTesorero ? 'tesorero' : 'integrante',
        nombre: resolved.nombre,
      );
    } else {
      await _store.clearActiveSemillero();
    }
  }

  Future<void> _actualizarTutorial() async {
    final TutorialStore? store = _tutorialStore;
    final UserModel? user = _user;
    if (store == null || user == null || !user.isProfileComplete) {
      _tutorialPendiente = false;
      return;
    }
    _tutorialPendiente = !await store.hasSeen(user.id);
  }

  /// Marca el recorrido inicial como visto para esta cuenta.
  Future<void> marcarTutorialVisto() async {
    final TutorialStore? store = _tutorialStore;
    final UserModel? user = _user;
    if (store != null && user != null) {
      await store.markSeen(user.id);
    }
    _tutorialPendiente = false;
    notifyListeners();
  }

  Future<void> _clearLocalSession() async {
    _user = null;
    _semilleros = <SemilleroMembership>[];
    _activeSemillero = null;
    _tutorialPendiente = false;
    await _store.clearAll();
  }
}
