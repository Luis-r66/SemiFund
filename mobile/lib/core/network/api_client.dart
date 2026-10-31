import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/session_storage.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

class ApiClient {
  ApiClient({required SessionStore store, String? baseUrl, Dio? dio})
    : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      sendTimeout: AppConfig.sendTimeout,
      responseType: ResponseType.json,
      headers: const <String, dynamic>{'Accept': 'application/json'},
    );
    _dio.interceptors.add(
      AuthInterceptor(
        store: store,
        onUnauthorized: () => onUnauthorized?.call(),
      ),
    );
  }

  final Dio _dio;

  /// Callback conectado por `main` a `SessionProvider.expireSession`.
  void Function()? onUnauthorized;

  Dio get raw => _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _execute(
      () => _dio.get<dynamic>(path, queryParameters: queryParameters),
    );
  }

  Future<dynamic> post(String path, {Object? data}) {
    return _execute(() => _dio.post<dynamic>(path, data: data));
  }

  Future<dynamic> put(String path, {Object? data}) {
    return _execute(() => _dio.put<dynamic>(path, data: data));
  }

  Future<dynamic> patch(String path, {Object? data}) {
    return _execute(() => _dio.patch<dynamic>(path, data: data));
  }

  Future<dynamic> delete(String path, {Object? data}) {
    return _execute(() => _dio.delete<dynamic>(path, data: data));
  }

  Future<Response<List<int>>> getBytes(String path) async {
    try {
      return await _dio.get<List<int>>(
        path,
        options: Options(
          responseType: ResponseType.bytes,
          headers: const <String, dynamic>{'Accept': 'text/csv'},
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<dynamic> _execute(Future<Response<dynamic>> Function() request) async {
    try {
      final Response<dynamic> response = await request();
      return response.data;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
