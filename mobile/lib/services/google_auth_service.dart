import 'package:google_sign_in/google_sign_in.dart';

import '../core/config/app_config.dart';

/// Error legible para el usuario cuando el flujo de Google falla.
class GoogleAuthException implements Exception {
  const GoogleAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Obtiene el idToken de Google en Android.
/// El backend valida ese token con el Web Client ID; aquí no se guarda nada.
class GoogleAuthService {
  bool _inicializado = false;

  Future<String?> obtenerIdToken() async {
    final GoogleSignIn google = GoogleSignIn.instance;
    try {
      if (!_inicializado) {
        await google.initialize(serverClientId: AppConfig.googleWebClientId);
        _inicializado = true;
      }
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
