import 'dart:convert';
import 'dart:typed_data';

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
        onSemilleroEliminado: () => onSemilleroEliminado?.call(),
      ),
    );
  }

  final Dio _dio;

  /// Callback conectado por `main` a `SessionProvider.expireSession`.
  void Function()? onUnauthorized;

  /// Callback conectado por `main` a `SessionProvider.descartarSemilleroEliminado`.
  void Function()? onSemilleroEliminado;

  Dio get raw => _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _execute(
      () => _dio.get<dynamic>(path, queryParameters: queryParameters),
    );
  }

  Future<dynamic> post(String path, {Object? data}) {
    return _execute(() => _dio.post<dynamic>(path, data: data));
  }

  /// Sube un archivo binario (por ejemplo la plantilla .xlsx) como cuerpo.
  Future<dynamic> postBytes(
    String path,
    Uint8List bytes, {
    String contentType = 'application/octet-stream',
  }) {
    return _execute(
      () => _dio.post<dynamic>(
        path,
        data: bytes,
        options: Options(
          contentType: contentType,
          responseType: ResponseType.json,
          headers: const <String, dynamic>{'Accept': 'application/json'},
        ),
      ),
    );
  }

  Future<dynamic> put(String path, {Object? data}) {
    return _execute(() => _dio.put<dynamic>(path, data: data));
  }

  /// Reemplaza un archivo como multipart (por ejemplo, la plantilla nueva de
  /// un documento conservando su nombre y sus etiquetas).
  Future<dynamic> putMultipart(
    String path, {
    required Uint8List bytes,
    required String filename,
    required String contentType,
    String field = 'archivo',
    Map<String, dynamic> fields = const <String, dynamic>{},
  }) {
    final FormData data = FormData.fromMap(<String, dynamic>{
      ...fields,
      field: MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: DioMediaType.parse(contentType),
      ),
    });
    return _execute(
      () => _dio.put<dynamic>(
        path,
        data: data,
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      ),
    );
  }

  /// Sube un archivo como multipart (comprobantes de abonos), con campos
  /// adicionales como monto o referencia.
  Future<dynamic> postMultipart(
    String path, {
    required Uint8List bytes,
    required String filename,
    required String contentType,
    String field = 'comprobante',
    Map<String, dynamic> fields = const <String, dynamic>{},
  }) {
    final FormData data = FormData.fromMap(<String, dynamic>{
      ...fields,
      field: MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: DioMediaType.parse(contentType),
      ),
    });
    return _execute(
      () => _dio.post<dynamic>(
        path,
        data: data,
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      ),
    );
  }

  Future<dynamic> patch(String path, {Object? data}) {
    return _execute(() => _dio.patch<dynamic>(path, data: data));
  }

  Future<dynamic> delete(String path, {Object? data}) {
    return _execute(() => _dio.delete<dynamic>(path, data: data));
  }

  Future<Response<List<int>>> getBytes(
    String path, {
    String accept = 'text/csv',
  }) async {
    try {
      return await _dio.get<List<int>>(
        path,
        options: Options(
          responseType: ResponseType.bytes,
          headers: <String, dynamic>{'Accept': accept},
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// Envía datos y recibe un archivo binario (documentos generados). Si el
  /// servidor responde con un error en JSON, se conserva su mensaje.
  Future<Response<List<int>>> postForBytes(
    String path, {
    Object? data,
    String accept = 'application/octet-stream',
  }) async {
    try {
      return await _dio.post<List<int>>(
        path,
        data: data,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 60),
          headers: <String, dynamic>{'Accept': accept},
        ),
      );
    } on DioException catch (error) {
      final dynamic cuerpo = error.response?.data;
      if (cuerpo is List<int>) {
        try {
          final dynamic json = jsonDecode(utf8.decode(cuerpo));
          throw ApiException.fromResponse(
            statusCode: error.response?.statusCode,
            data: json,
          );
        } catch (traduccion) {
          if (traduccion is ApiException) rethrow;
        }
      }
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
