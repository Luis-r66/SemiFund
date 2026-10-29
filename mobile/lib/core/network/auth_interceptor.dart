import 'package:dio/dio.dart';

import '../storage/session_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required SessionStore store, this.onUnauthorized})
    : _store = store;

  final SessionStore _store;
  final void Function()? onUnauthorized;

  static bool _isLoginOrRegister(String path) {
    return path.contains('/auth/login') || path.contains('/auth/register');
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['Content-Type'] = 'application/json';

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
    if (statusCode == 401 && !_isLoginOrRegister(err.requestOptions.path)) {
      onUnauthorized?.call();
    }
    handler.next(err);
  }
}
