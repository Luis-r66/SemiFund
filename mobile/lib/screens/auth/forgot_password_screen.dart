import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/session_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/buttons.dart';
import '../../widgets/error_banner.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _code = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  bool _codeSent = false;
  bool _loading = false;
  String? _emailError;
  String? _codeError;
  String? _passwordError;
  String? _confirmError;
  String? _error;

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    for (final TextEditingController controller in <TextEditingController>[
      _email,
      _code,
      _password,
      _confirm,
    ]) {
      controller.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final String email = _email.text.trim();
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _emailError = 'Ingresa un correo válido.');
      return;
    }
    setState(() {
      _loading = true;
      _emailError = null;
      _error = null;
    });
    try {
      await context.read<SessionProvider>().forgotPassword(email);
      if (!mounted) return;
      setState(() => _codeSent = true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No se pudo enviar el código. Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final String code = _code.text.trim();
    final String password = _password.text;
    final String confirm = _confirm.text;
    setState(() {
      _codeError = code.length == 6 ? null : 'Ingresa el código de 6 dígitos.';
      _passwordError = password.length < 8
          ? 'La contraseña debe tener al menos 8 caracteres.'
          : null;
      _confirmError = confirm != password
          ? 'Las contraseñas no coinciden.'
          : null;
      _error = null;
    });
    if (_codeError != null || _passwordError != null || _confirmError != null) {
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<SessionProvider>().resetPassword(
        email: _email.text.trim(),
        code: code,
        password: password,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada. Inicia sesión.')),
      );
      context.go('/login');
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No se pudo cambiar la contraseña. Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AppTopBar(
              title: 'Recuperar contraseña',
              onBack: () {
                if (_codeSent) {
                  setState(() => _codeSent = false);
                } else {
                  context.pop();
                }
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _codeSent
                          ? 'Escribe el código que enviamos a tu correo y define una nueva contraseña.'
                          : 'Ingresa tu correo electrónico y te enviaremos un código de recuperación.',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.ink2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!_codeSent) ...<Widget>[
                      LabeledField(
                        label: 'Correo electrónico',
                        error: _emailError,
                        child: AppTextField(
                          controller: _email,
                          hintText: 'nombre@correo.com',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          autofillHints: const <String>[AutofillHints.email],
                          onSubmitted: (_) => _sendCode(),
                        ),
                      ),
                      if (_error != null) ErrorBanner(message: _error!),
                    ] else ...<Widget>[
                      _InfoBanner(
                        message:
                            'Código enviado a ${_email.text.trim()}. Si no lo encuentras, revisa spam.',
                      ),
                      const SizedBox(height: 18),
                      LabeledField(
                        label: 'Código de recuperación',
                        error: _codeError,
                        child: NumericCodeField(controller: _code),
                      ),
                      LabeledField(
                        label: 'Nueva contraseña',
                        error: _passwordError,
                        child: PasswordField(
                          controller: _password,
                          textInputAction: TextInputAction.next,
                          autofillHints: const <String>[
                            AutofillHints.newPassword,
                          ],
                        ),
                      ),
                      LabeledField(
                        label: 'Confirmar contraseña',
                        error: _confirmError,
                        child: PasswordField(
                          controller: _confirm,
                          hintText: 'Repite la nueva contraseña',
                          textInputAction: TextInputAction.done,
                          autofillHints: const <String>[
                            AutofillHints.newPassword,
                          ],
                          onSubmitted: (_) => _resetPassword(),
                        ),
                      ),
                      if (_error != null) ErrorBanner(message: _error!),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: _loading ? null : _sendCode,
                          child: const Text('Reenviar código'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: PrimaryButton(
                label: _codeSent ? 'Restablecer contraseña' : 'Enviar código',
                loading: _loading,
                onPressed: _loading
                    ? null
                    : (_codeSent ? _resetPassword : _sendCode),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(LucideIcons.info, size: 17, color: AppColors.ink2),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.smallMedium.copyWith(color: AppColors.ink2),
            ),
          ),
        ],
      ),
    );
  }
}
