import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi;

/// Botón oficial de Google Identity Services para la versión web.
///
/// En web `google_sign_in` no permite pedir el token con una llamada normal:
/// Google exige su propio botón. Al completar el flujo, el idToken llega por el
/// stream `authenticationEvents`.
Widget buildGoogleWebButton({
  required ValueChanged<String> onIdToken,
  required void Function(String message) onError,
}) {
  return _GoogleWebButton(onIdToken: onIdToken, onError: onError);
}

class _GoogleWebButton extends StatefulWidget {
  const _GoogleWebButton({required this.onIdToken, required this.onError});

  final ValueChanged<String> onIdToken;
  final void Function(String message) onError;

  @override
  State<_GoogleWebButton> createState() => _GoogleWebButtonState();
}

class _GoogleWebButtonState extends State<_GoogleWebButton> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _suscripcion;

  @override
  void initState() {
    super.initState();
    _suscripcion = GoogleSignIn.instance.authenticationEvents.listen(
      _onEvento,
      onError: (Object _) => widget.onError(
        'No pudimos conectar con Google. Revisa tu cuenta e intenta de nuevo.',
      ),
    );
  }

  void _onEvento(GoogleSignInAuthenticationEvent evento) {
    if (evento is! GoogleSignInAuthenticationEventSignIn) return;
    final String? idToken = evento.user.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      widget.onError(
        'Google no entregó la información necesaria. Intenta de nuevo.',
      );
      return;
    }
    widget.onIdToken(idToken);
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double ancho = constraints.maxWidth.clamp(280.0, 400.0);
        return Center(
          child: gsi.renderButton(
            configuration: gsi.GSIButtonConfiguration(
              size: gsi.GSIButtonSize.large,
              theme: gsi.GSIButtonTheme.outline,
              text: gsi.GSIButtonText.continueWith,
              shape: gsi.GSIButtonShape.rectangular,
              logoAlignment: gsi.GSIButtonLogoAlignment.center,
              minimumWidth: ancho,
              locale: 'es',
            ),
          ),
        );
      },
    );
  }
}
