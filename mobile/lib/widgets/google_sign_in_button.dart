import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import 'google_web_button_stub.dart'
    if (dart.library.js_interop) 'google_web_button.dart'
    as web;

/// Botón sobrio para "Continuar con Google".
/// Se usa en login y registro; no usa el azul de la marca.
///
/// En Android abre el selector de cuentas nativo. En web muestra el botón
/// oficial de Google, que entrega el idToken por su propio flujo.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onIdToken,
    this.onPressed,
    this.onError,
    this.loading = false,
  });

  /// Recibe el idToken ya validado por Google (solo en web).
  final ValueChanged<String> onIdToken;

  /// Flujo nativo (Android).
  final VoidCallback? onPressed;

  /// Mensaje legible cuando Google falla antes de llegar al backend.
  final void Function(String message)? onError;

  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      if (loading) {
        return const SizedBox(
          height: 44,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
              ),
            ),
          ),
        );
      }
      return web.buildGoogleWebButton(
        onIdToken: onIdToken,
        onError: onError ?? (String _) {},
      );
    }

    final bool enabled = onPressed != null && !loading;
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: AppColors.paper,
          disabledForegroundColor: AppColors.ink3,
          side: const BorderSide(color: AppColors.line),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.button,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.ink,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      'G',
                      style: TextStyle(
                        color: AppColors.paper,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Flexible(
                    child: Text(
                      'Continuar con Google',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
