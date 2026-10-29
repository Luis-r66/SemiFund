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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _namesController = TextEditingController();
  final TextEditingController _surnamesController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final FocusNode _surnamesFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();

  String? _namesError;
  String? _surnamesError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _error;

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    for (final TextEditingController controller in <TextEditingController>[
      _namesController,
      _surnamesController,
      _emailController,
      _passwordController,
      _confirmController,
    ]) {
      controller.addListener(_onFormChanged);
    }
  }

  void _onFormChanged() => setState(() {});

  bool get _canSubmit {
    return _namesController.text.trim().isNotEmpty &&
        _surnamesController.text.trim().isNotEmpty &&
        _emailRegex.hasMatch(_emailController.text.trim()) &&
        _passwordController.text.length >= 8 &&
        _confirmController.text == _passwordController.text;
  }

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[
      _namesController,
      _surnamesController,
      _emailController,
      _passwordController,
      _confirmController,
    ]) {
      controller.removeListener(_onFormChanged);
      controller.dispose();
    }
    _surnamesFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  bool _validate() {
    final String names = _namesController.text.trim();
    final String surnames = _surnamesController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    final String confirm = _confirmController.text;
    setState(() {
      _namesError = names.isEmpty ? 'Ingresa tus nombres.' : null;
      _surnamesError = surnames.isEmpty ? 'Ingresa tus apellidos.' : null;
      _emailError = email.isEmpty
          ? 'Ingresa tu correo institucional.'
          : (!_emailRegex.hasMatch(email) ? 'Ingresa un correo válido.' : null);
      _passwordError = password.length < 8
          ? 'La contraseña debe tener al menos 8 caracteres.'
          : null;
      _confirmError = confirm != password
          ? 'Las contraseñas no coinciden.'
          : null;
      _error = null;
    });
    return _namesError == null &&
        _surnamesError == null &&
        _emailError == null &&
        _passwordError == null &&
        _confirmError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    FocusScope.of(context).unfocus();

    final SessionProvider session = context.read<SessionProvider>();
    try {
      await session.register(
        nombres: _namesController.text.trim(),
        apellidos: _surnamesController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo crear la cuenta. Intenta de nuevo.');
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
                    Text('Crea tu cuenta', style: AppTextStyles.h1),
                    const SizedBox(height: 6),
                    Text(
                      'Una sola cuenta para todos tus semilleros.',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.ink2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    LabeledField(
                      label: 'Nombres',
                      error: _namesError,
                      child: AppTextField(
                        controller: _namesController,
                        hintText: 'Ej. Luis Ernesto',
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const <String>[AutofillHints.givenName],
                        onChanged: (_) {
                          if (_namesError != null) {
                            setState(() => _namesError = null);
                          }
                        },
                        onSubmitted: (_) => _surnamesFocus.requestFocus(),
                      ),
                    ),
                    LabeledField(
                      label: 'Apellidos',
                      error: _surnamesError,
                      child: AppTextField(
                        controller: _surnamesController,
                        focusNode: _surnamesFocus,
                        hintText: 'Ej. Ríos Pérez',
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const <String>[AutofillHints.familyName],
                        onChanged: (_) {
                          if (_surnamesError != null) {
                            setState(() => _surnamesError = null);
                          }
                        },
                        onSubmitted: (_) => _emailFocus.requestFocus(),
                      ),
                    ),
                    LabeledField(
                      label: 'Correo institucional',
                      error: _emailError,
                      child: AppTextField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        hintText: 'nombre@universidad.edu.co',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const <String>[
                          AutofillHints.newUsername,
                        ],
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
                      helper:
                          '${_passwordController.text.length}/8 caracteres mínimos',
                      child: PasswordField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        textInputAction: TextInputAction.next,
                        autofillHints: const <String>[
                          AutofillHints.newPassword,
                        ],
                        onChanged: (_) {
                          if (_passwordError != null) {
                            setState(() => _passwordError = null);
                          }
                        },
                        onSubmitted: (_) => _confirmFocus.requestFocus(),
                      ),
                    ),
                    LabeledField(
                      label: 'Confirmar contraseña',
                      error: _confirmError,
                      child: PasswordField(
                        controller: _confirmController,
                        focusNode: _confirmFocus,
                        hintText: 'Repite tu contraseña',
                        textInputAction: TextInputAction.done,
                        autofillHints: const <String>[
                          AutofillHints.newPassword,
                        ],
                        onChanged: (_) {
                          if (_confirmError != null) {
                            setState(() => _confirmError = null);
                          }
                        },
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    if (visibleError != null) ...<Widget>[
                      const SizedBox(height: 8),
                      ErrorBanner(message: visibleError),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: PrimaryButton(
                label: 'Crear cuenta',
                loading: session.isBusy,
                onPressed: _canSubmit && !session.isBusy ? _submit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
