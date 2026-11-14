import 'package:semi_fund/core/storage/session_storage.dart';
import 'package:semi_fund/models/app_release.dart';
import 'package:semi_fund/services/app_update_service.dart';
import 'package:semi_fund/services/tutorial_service.dart';

class FakeAppUpdateGateway implements AppUpdateGateway {
  FakeAppUpdateGateway({this.version = '1.3.0', this.build = '7'});

  String version;
  String build;
  bool due = false;
  AppRelease? release;
  bool abrirLlamado = false;

  @override
  Future<String> versionActual() async => version;

  @override
  Future<String> buildActual() async => build;

  @override
  bool get consultaVencida => due;

  @override
  Future<AppRelease?> buscar({bool forzar = false}) async => release;

  @override
  Future<void> abrirDescarga(AppRelease release) async {
    abrirLlamado = true;
  }
}

class FakeTutorialStore implements TutorialStore {
  bool seen = false;

  @override
  Future<bool> hasSeen(String userId) async => seen;

  @override
  Future<void> markSeen(String userId) async => seen = true;
}

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
