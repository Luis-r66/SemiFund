import 'package:flutter_test/flutter_test.dart';
import 'package:semi_fund/core/network/auth_interceptor.dart';

void main() {
  test('un 401 al cambiar la contraseña no cierra la sesión', () {
    expect(debeExpirarSesion('/auth/password', 401), isFalse);
  });

  test('un 401 al iniciar sesión no cierra la sesión', () {
    expect(debeExpirarSesion('/auth/login', 401), isFalse);
  });

  test('un 401 al recuperar la contraseña no cierra la sesión', () {
    expect(debeExpirarSesion('/auth/reset-password', 401), isFalse);
    expect(debeExpirarSesion('/auth/forgot-password', 401), isFalse);
  });

  test('un 401 de un endpoint protegido sí cierra la sesión', () {
    expect(debeExpirarSesion('/contributions', 401), isTrue);
    expect(debeExpirarSesion('/semilleros/me', 401), isTrue);
  });

  test('otros errores no cierran la sesión', () {
    expect(debeExpirarSesion('/contributions', 403), isFalse);
    expect(debeExpirarSesion('/contributions', 500), isFalse);
    expect(debeExpirarSesion('/contributions', null), isFalse);
  });
}
