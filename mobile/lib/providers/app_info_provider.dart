import 'package:flutter/foundation.dart';

import '../models/app_release.dart';
import '../services/app_update_service.dart';

/// Estado de la versión instalada y de la última release disponible.
class AppInfoProvider extends ChangeNotifier {
  AppInfoProvider(this._service);

  final AppUpdateGateway _service;

  String _version = '';
  String _build = '';
  AppRelease? _release;
  bool _checking = false;
  String? _error;
  bool _dismissed = false;

  String get version => _version;
  String get build => _build;
  String get versionLabel =>
      _version.isEmpty ? 'SemiFund' : 'Versión $_version ($_build)';
  AppRelease? get release => _release;
  bool get hasUpdate => _release != null;
  bool get checking => _checking;
  String? get error => _error;
  bool get showBanner => hasUpdate && !_dismissed;

  /// Se llama una vez al arrancar: lee la versión y consulta GitHub como
  /// máximo una vez al día, sin interrumpir al usuario.
  Future<void> iniciar() async {
    await _cargarVersion();
    if (!_service.consultaVencida) return;
    try {
      _release = await _service.buscar();
      notifyListeners();
    } catch (_) {
      // Sin conexión o límite de GitHub: se reintenta en la próxima apertura.
    }
  }

  /// Búsqueda manual. Devuelve `true` si encontró una versión nueva.
  Future<bool> buscarAhora() async {
    if (_checking) return hasUpdate;
    _checking = true;
    _error = null;
    notifyListeners();
    try {
      await _cargarVersion();
      final AppRelease? release = await _service.buscar(forzar: true);
      _release = release;
      _dismissed = false;
      return release != null;
    } catch (_) {
      _error = 'No se pudo consultar GitHub. Revisa tu conexión.';
      return false;
    } finally {
      _checking = false;
      notifyListeners();
    }
  }

  Future<void> descargar() async {
    final AppRelease? release = _release;
    if (release == null) return;
    await _service.abrirDescarga(release);
  }

  void descartar() {
    if (_dismissed) return;
    _dismissed = true;
    notifyListeners();
  }

  Future<void> _cargarVersion() async {
    _version = await _service.versionActual();
    _build = await _service.buildActual();
    notifyListeners();
  }
}
