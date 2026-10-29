import 'package:semi_fund/core/storage/session_storage.dart';

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
