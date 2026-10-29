import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:semi_fund/core/network/api_exception.dart';

void main() {
  final RequestOptions options = RequestOptions(path: '/expenses');

  test('usa el mensaje del backend y clasifica 409', () {
    final DioException error = DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: options,
        statusCode: 409,
        data: <String, dynamic>{'error': 'Saldo insuficiente'},
      ),
    );

    final ApiException exception = ApiException.fromDio(error);
    expect(exception.kind, ApiErrorKind.conflict);
    expect(exception.statusCode, 409);
    expect(exception.message, 'Saldo insuficiente');
  });

  test('clasifica 401 como sesión expirada', () {
    final DioException error = DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: options,
        statusCode: 401,
        data: <String, dynamic>{'error': 'Token inválido o expirado'},
      ),
    );

    final ApiException exception = ApiException.fromDio(error);
    expect(exception.kind, ApiErrorKind.unauthorized);
    expect(exception.message, 'Token inválido o expirado');
  });

  test('clasifica timeout de conexión', () {
    final DioException error = DioException(
      requestOptions: options,
      type: DioExceptionType.connectionTimeout,
    );

    final ApiException exception = ApiException.fromDio(error);
    expect(exception.kind, ApiErrorKind.timeout);
    expect(exception.message, contains('tardó demasiado'));
  });

  test('usa mensaje por defecto si el backend no envía error', () {
    final ApiException exception = ApiException.fromResponse(statusCode: 403);
    expect(exception.kind, ApiErrorKind.forbidden);
    expect(exception.message, contains('permisos'));
  });
}
