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

enum SessionStatus { bootstrapping, unauthenticated, authenticated }

class SessionProvider extends ChangeNotifier {
  SessionProvider({
    required AuthService authService,
    required SemilleroService semilleroService,
    required SessionStore store,
  }) : _authService = authService,
       _semilleroService = semilleroService,
       _store = store;

  final AuthService _authService;
  final SemilleroService _semilleroService;
  final SessionStore _store;

  SessionStatus _status = SessionStatus.bootstrapping;
  UserModel? _user;
  List<SemilleroMembership> _semilleros = <SemilleroMembership>[];
  SemilleroMembership? _activeSemillero;
  String? _notice;
  String? _bootstrapError;
  bool _isBusy = false;
  bool _booting = false;
  bool _expiring = false;

  SessionStatus get status => _status;
  UserModel? get user => _user;
  List<SemilleroMembership> get semilleros => List.unmodifiable(_semilleros);
  SemilleroMembership? get activeSemillero => _activeSemillero;
  String? get notice => _notice;
  String? get bootstrapError => _bootstrapError;
  bool get isBusy => _isBusy;

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
    required String nombre,
    required String email,
    required String password,
  }) async {
    _isBusy = true;
    _notice = null;
    notifyListeners();

    try {
      final AuthResult result = await _authService.register(
        RegisterRequest(
          nombre: nombre.trim(),
          email: email.trim(),
          password: password,
        ),
      );
      await _store.saveToken(result.token);
      _user = result.user;
      _status = SessionStatus.authenticated;
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

  Future<void> _clearLocalSession() async {
    _user = null;
    _semilleros = <SemilleroMembership>[];
    _activeSemillero = null;
    await _store.clearAll();
  }
}
