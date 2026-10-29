import 'package:dio/dio.dart';

enum ApiErrorKind {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  validation,
  server,
  unknown,
}

class ApiException implements Exception {
  const ApiException({
    required this.message,
    required this.kind,
    this.statusCode,
  });

  final String message;
  final ApiErrorKind kind;
  final int? statusCode;

  bool get isUnauthorized => kind == ApiErrorKind.unauthorized;
  bool get isForbidden => kind == ApiErrorKind.forbidden;
  bool get isConflict => kind == ApiErrorKind.conflict;

  factory ApiException.fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException(
          kind: ApiErrorKind.timeout,
          message:
              'El servidor tardó demasiado en responder. Intenta de nuevo.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          kind: ApiErrorKind.network,
          message: 'No se pudo conectar con el servidor. Revisa tu conexión e inténtalo otra vez.',
        );
      case DioExceptionType.cancel:
        return const ApiException(
          kind: ApiErrorKind.unknown,
          message: 'La solicitud fue cancelada.',
        );
      case DioExceptionType.badCertificate:
        return const ApiException(
          kind: ApiErrorKind.network,
          message: 'No se pudo validar el certificado del servidor.',
        );
      case DioExceptionType.badResponse:
        return ApiException.fromResponse(
          statusCode: error.response?.statusCode,
          data: error.response?.data,
        );
      case DioExceptionType.unknown:
        return const ApiException(
          kind: ApiErrorKind.network,
          message: 'Ocurrió un problema de conexión. Intenta de nuevo.',
        );
    }
  }

  factory ApiException.fromResponse({int? statusCode, dynamic data}) {
    final serverMessage = _extractMessage(data);
    final kind = _kindFor(statusCode);
    return ApiException(
      statusCode: statusCode,
      kind: kind,
      message: serverMessage ?? _fallbackMessage(kind),
    );
  }

  static ApiErrorKind _kindFor(int? statusCode) {
    switch (statusCode) {
      case 400:
        return ApiErrorKind.validation;
      case 401:
        return ApiErrorKind.unauthorized;
      case 403:
        return ApiErrorKind.forbidden;
      case 404:
        return ApiErrorKind.notFound;
      case 409:
        return ApiErrorKind.conflict;
      case 500:
      case 502:
      case 503:
        return ApiErrorKind.server;
      default:
        return ApiErrorKind.unknown;
    }
  }

  static String _fallbackMessage(ApiErrorKind kind) {
    switch (kind) {
      case ApiErrorKind.unauthorized:
        return 'Tu sesión expiró. Inicia sesión de nuevo.';
      case ApiErrorKind.forbidden:
        return 'No tienes permisos para realizar esta acción.';
      case ApiErrorKind.notFound:
        return 'No encontramos la información solicitada.';
      case ApiErrorKind.conflict:
        return 'No se pudo completar la operación.';
      case ApiErrorKind.validation:
        return 'Revisa los datos ingresados.';
      case ApiErrorKind.server:
        return 'El servidor presentó un error. Intenta más tarde.';
      case ApiErrorKind.network:
      case ApiErrorKind.timeout:
        return 'No se pudo conectar con el servidor.';
      case ApiErrorKind.unknown:
        return 'Ocurrió un error inesperado.';
    }
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map && data['error'] is String) {
      final String message = data['error'] as String;
      if (message.trim().isNotEmpty) return message;
    }
    if (data is Map && data['mensaje'] is String) {
      final String message = data['mensaje'] as String;
      if (message.trim().isNotEmpty) return message;
    }
    return null;
  }

  @override
  String toString() => 'ApiException($statusCode, $kind, $message)';
}
