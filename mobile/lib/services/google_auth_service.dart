import 'package:google_sign_in/google_sign_in.dart';

import '../core/config/app_config.dart';

/// Error legible para el usuario cuando el flujo de Google falla.
class GoogleAuthException implements Exception {
  const GoogleAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Obtiene el idToken de Google.
/// En Android el Web Client ID viaja como `serverClientId`; en web es además
/// el `clientId` del propio cliente JavaScript. El backend valida ese token.
class GoogleAuthService {
  static Future<void>? _inicializacion;

  /// Deja listo el cliente de Google. Conviene llamarlo al arrancar la web:
  /// si el script se carga después del clic, el navegador puede bloquear la
  /// ventana emergente del selector de cuentas.
  static Future<void> preparar() {
    return _inicializacion ??= GoogleSignIn.instance
        .initialize(
          clientId: AppConfig.googleWebClientId,
          serverClientId: AppConfig.googleWebClientId,
        )
        .catchError((Object _) {
          // Se reintenta en el siguiente intento de inicio de sesión.
          _inicializacion = null;
        });
  }

  Future<String?> obtenerIdToken() async {
    final GoogleSignIn google = GoogleSignIn.instance;
    try {
      await preparar();
      final GoogleSignInAccount cuenta = await google.authenticate();
      final String? idToken = cuenta.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const GoogleAuthException(
          'Google no entregó la información necesaria. Intenta de nuevo.',
        );
      }
      return idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      throw const GoogleAuthException(
        'No pudimos conectar con Google. Revisa tu cuenta e intenta de nuevo.',
      );
    }
  }
}
