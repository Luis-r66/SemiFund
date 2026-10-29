import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/session_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/buttons.dart';
import '../../widgets/error_banner.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  String? _emailError;
  String? _passwordError;
  String? _error;

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool _validate() {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    setState(() {
      _emailError = email.isEmpty
          ? 'Ingresa tu correo institucional.'
          : (!_emailRegex.hasMatch(email) ? 'Ingresa un correo válido.' : null);
      _passwordError = password.isEmpty ? 'Ingresa tu contraseña.' : null;
      _error = null;
    });
    return _emailError == null && _passwordError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    FocusScope.of(context).unfocus();

    final SessionProvider session = context.read<SessionProvider>();
    try {
      await session.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo iniciar sesión. Intenta de nuevo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final SessionProvider session = context.watch<SessionProvider>();
    final String? visibleError = _error ?? session.notice;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => context.pop(),
                        tooltip: 'Atrás',
                        icon: const Icon(LucideIcons.arrowLeft, size: 20),
                        constraints: const BoxConstraints.tightFor(
                          width: 40,
                          height: 40,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('Inicia sesión', style: AppTextStyles.h1),
                    const SizedBox(height: 6),
                    Text(
                      'Usa la cuenta con la que te registraste.',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.ink2,
                      ),
                    ),
                    const SizedBox(height: 28),
                    LabeledField(
                      label: 'Correo institucional',
                      error: _emailError,
                      child: AppTextField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        hintText: 'nombre@universidad.edu.co',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const <String>[AutofillHints.email],
                        onChanged: (_) {
                          if (_emailError != null) {
                            setState(() => _emailError = null);
                          }
                        },
                        onSubmitted: (_) => _passwordFocus.requestFocus(),
                      ),
                    ),
                    LabeledField(
                      label: 'Contraseña',
                      error: _passwordError,
                      child: PasswordField(
                        controller: _passwordController,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) {
                          if (_passwordError != null) {
                            setState(() => _passwordError = null);
                          }
                        },
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () => context.push('/register'),
                        child: Text.rich(
                          TextSpan(
                            text: '¿No tienes cuenta? ',
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.ink2,
                            ),
                            children: const <TextSpan>[
                              TextSpan(
                                text: 'Crear cuenta',
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (visibleError != null) ...<Widget>[
                      const SizedBox(height: 16),
                      ErrorBanner(message: visibleError),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: PrimaryButton(
                label: 'Entrar',
                loading: session.isBusy,
                onPressed: session.isBusy ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
