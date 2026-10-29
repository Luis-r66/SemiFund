import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SessionStore {
  Future<String?> readToken();
  Future<void> saveToken(String token);
  Future<void> clearToken();
  Future<String?> readSemilleroId();
  Future<String?> readRole();
  Future<String?> readSemilleroName();
  Future<void> saveActiveSemillero({
    required String id,
    required String role,
    required String nombre,
  });
  Future<void> clearActiveSemillero();
  Future<void> clearAll();
}

class SessionStorage implements SessionStore {
  SessionStorage({
    required SharedPreferences preferences,
    FlutterSecureStorage? secureStorage,
  }) : _preferences = preferences,
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'semi_fund_token';
  static const String _semilleroIdKey = 'semi_fund_semillero_id';
  static const String _roleKey = 'semi_fund_role';
  static const String _semilleroNameKey = 'semi_fund_semillero_name';

  final SharedPreferences _preferences;
  final FlutterSecureStorage _secureStorage;

  @override
  Future<String?> readToken() => _secureStorage.read(key: _tokenKey);

  @override
  Future<void> saveToken(String token) =>
      _secureStorage.write(key: _tokenKey, value: token);

  @override
  Future<void> clearToken() => _secureStorage.delete(key: _tokenKey);

  @override
  Future<String?> readSemilleroId() async =>
      _preferences.getString(_semilleroIdKey);

  @override
  Future<String?> readRole() async => _preferences.getString(_roleKey);

  @override
  Future<String?> readSemilleroName() async =>
      _preferences.getString(_semilleroNameKey);

  @override
  Future<void> saveActiveSemillero({
    required String id,
    required String role,
    required String nombre,
  }) async {
    await _preferences.setString(_semilleroIdKey, id);
    await _preferences.setString(_roleKey, role);
    await _preferences.setString(_semilleroNameKey, nombre);
  }

  @override
  Future<void> clearActiveSemillero() async {
    await _preferences.remove(_semilleroIdKey);
    await _preferences.remove(_roleKey);
    await _preferences.remove(_semilleroNameKey);
  }

  @override
  Future<void> clearAll() async {
    await clearToken();
    await clearActiveSemillero();
  }
}
