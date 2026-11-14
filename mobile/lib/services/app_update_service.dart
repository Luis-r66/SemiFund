import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/utils/version_utils.dart';
import '../models/app_release.dart';

/// Contrato de la consulta de actualizaciones, para poder simularlo en pruebas.
abstract class AppUpdateGateway {
  Future<String> versionActual();
  Future<String> buildActual();
  bool get consultaVencida;
  Future<AppRelease?> buscar({bool forzar = false});
  Future<void> abrirDescarga(AppRelease release);
}

/// Consulta la última release pública de SemiFund en GitHub y la compara con
/// la versión instalada. La app se distribuye como APK, así que la descarga
/// se abre en el navegador y el usuario confirma la instalación.
class AppUpdateService implements AppUpdateGateway {
  AppUpdateService({required SharedPreferences preferences, Dio? dio})
    : _preferences = preferences,
      _dio = dio ?? Dio();

  static const String repositorio = 'Luis-r66/SemiFund';
  static const String _claveUltimaConsulta = 'app_update_last_check';
  static const Duration _intervalo = Duration(hours: 24);

  final SharedPreferences _preferences;
  final Dio _dio;

  @override
  Future<String> versionActual() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    return info.version;
  }

  @override
  Future<String> buildActual() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    return info.buildNumber;
  }

  @override
  bool get consultaVencida {
    final int? ultima = _preferences.getInt(_claveUltimaConsulta);
    if (ultima == null) return true;
    final DateTime fecha = DateTime.fromMillisecondsSinceEpoch(ultima);
    return DateTime.now().difference(fecha) >= _intervalo;
  }

  /// Devuelve la release si hay una versión más nueva que la instalada.
  /// Con [forzar] ignora el límite de una consulta diaria.
  @override
  Future<AppRelease?> buscar({bool forzar = false}) async {
    if (!forzar && !consultaVencida) return null;

    final String actual = await versionActual();
    final AppRelease? release = await _ultimaRelease();
    await _preferences.setInt(
      _claveUltimaConsulta,
      DateTime.now().millisecondsSinceEpoch,
    );

    if (release == null) return null;
    return compararVersiones(release.version, actual) > 0 ? release : null;
  }

  Future<AppRelease?> _ultimaRelease() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      'https://api.github.com/repos/$repositorio/releases/latest',
      options: Options(
        headers: const <String, dynamic>{
          'Accept': 'application/vnd.github+json',
        },
      ),
    );
    final Object? payload = response.data;
    if (payload is! Map) return null;
    final Map<String, dynamic> data = Map<String, dynamic>.from(payload);

    final String tag = (data['tag_name'] ?? '').toString();
    if (tag.isEmpty) return null;

    final List<dynamic> assets = data['assets'] is List
        ? data['assets'] as List<dynamic>
        : const <dynamic>[];

    Map<String, dynamic>? apk;
    for (final dynamic asset in assets) {
      if (asset is! Map) continue;
      final Map<String, dynamic> item = Map<String, dynamic>.from(asset);
      if ((item['name'] ?? '').toString() == 'SemiFund.apk') {
        apk = item;
        break;
      }
    }
    if (apk == null) {
      for (final dynamic asset in assets) {
        if (asset is! Map) continue;
        final Map<String, dynamic> item = Map<String, dynamic>.from(asset);
        if ((item['name'] ?? '').toString().toLowerCase().endsWith('.apk')) {
          apk = item;
          break;
        }
      }
    }

    final String downloadUrl =
        (apk?['browser_download_url'] ?? data['html_url'] ?? '').toString();
    if (downloadUrl.isEmpty) return null;

    return AppRelease(
      version: normalizarVersion(tag),
      name: (data['name'] ?? tag).toString(),
      notes: (data['body'] ?? '').toString(),
      downloadUrl: downloadUrl,
      pageUrl: (data['html_url'] ?? '').toString(),
      sizeBytes: apk == null ? 0 : int.tryParse('${apk['size']}') ?? 0,
      publishedAt: DateTime.tryParse((data['published_at'] ?? '').toString()),
    );
  }

  @override
  Future<void> abrirDescarga(AppRelease release) async {
    await launchUrl(
      Uri.parse(release.downloadUrl),
      mode: LaunchMode.externalApplication,
    );
  }
}
