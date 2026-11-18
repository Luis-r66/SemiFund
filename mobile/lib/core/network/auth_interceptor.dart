import 'package:dio/dio.dart';

import '../storage/session_storage.dart';

/// Rutas de `/auth/` donde un `401` significa que los datos enviados son
/// incorrectos, no que la sesión haya vencido. Cambiar la contraseña con la
/// actual equivocada debe mostrar el error en el formulario y no cerrar sesión.
bool debeExpirarSesion(String path, int? statusCode) {
  if (statusCode != 401) return false;
  const List<String> rutasSinExpirar = <String>[
    '/auth/login',
    '/auth/register',
    '/auth/google',
    '/auth/password',
    '/auth/forgot-password',
    '/auth/reset-password',
  ];
  for (final String ruta in rutasSinExpirar) {
    if (path.contains(ruta)) return false;
  }
  return true;
}

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SessionStore store,
    this.onUnauthorized,
    this.onSemilleroEliminado,
  }) : _store = store;

  final SessionStore _store;
  final void Function()? onUnauthorized;
  final void Function()? onSemilleroEliminado;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.contentType == null &&
        !options.headers.containsKey('Content-Type')) {
      options.headers['Content-Type'] = 'application/json';
    }

    final String? token = await _store.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    if (!options.path.startsWith('/auth/')) {
      final String? semilleroId = await _store.readSemilleroId();
      if (semilleroId != null && semilleroId.isNotEmpty) {
        options.headers['X-Semillero-Id'] = semilleroId;
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final int? statusCode = err.response?.statusCode;
    if (debeExpirarSesion(err.requestOptions.path, statusCode)) {
      onUnauthorized?.call();
    }
    // El semillero fue eliminado por su creador: la sesión local debe soltarlo
    // para que la app vuelva a "Mis semilleros" en lugar de quedar bloqueada.
    final Object? data = err.response?.data;
    if (statusCode == 403 &&
        data is Map &&
        data['code'] == 'semillero_eliminado') {
      onSemilleroEliminado?.call();
    }
    handler.next(err);
  }
}
