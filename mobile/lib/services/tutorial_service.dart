import 'package:shared_preferences/shared_preferences.dart';

/// Guarda si cada cuenta ya vio el recorrido de bienvenida.
abstract class TutorialStore {
  Future<bool> hasSeen(String userId);
  Future<void> markSeen(String userId);
}

class TutorialService implements TutorialStore {
  TutorialService(this._preferences);

  static const String _prefijo = 'tutorial_v1_';

  final SharedPreferences _preferences;

  String _clave(String userId) => '$_prefijo$userId';

  @override
  Future<bool> hasSeen(String userId) async {
    if (userId.isEmpty) return true;
    return _preferences.getBool(_clave(userId)) ?? false;
  }

  @override
  Future<void> markSeen(String userId) async {
    if (userId.isEmpty) return;
    await _preferences.setBool(_clave(userId), true);
  }
}
