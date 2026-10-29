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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _error;

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _nameController.addListener(_onFormChanged);
    _emailController.addListener(_onFormChanged);
  }

  void _onPasswordChanged() => setState(() {});

  void _onFormChanged() => setState(() {});

  bool get _canSubmit {
    return _nameController.text.trim().isNotEmpty &&
        _emailRegex.hasMatch(_emailController.text.trim()) &&
        _passwordController.text.length >= 8;
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _nameController.removeListener(_onFormChanged);
    _emailController.removeListener(_onFormChanged);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool _validate() {
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    setState(() {
      _nameError = name.isEmpty ? 'Ingresa tu nombre completo.' : null;
      _emailError = email.isEmpty
          ? 'Ingresa tu correo institucional.'
          : (!_emailRegex.hasMatch(email) ? 'Ingresa un correo válido.' : null);
      _passwordError = password.length < 8
          ? 'La contraseña debe tener al menos 8 caracteres.'
          : null;
      _error = null;
    });
    return _nameError == null && _emailError == null && _passwordError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    FocusScope.of(context).unfocus();

    final SessionProvider session = context.read<SessionProvider>();
    try {
      await session.register(
        nombre: _nameController.text.trim(),
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
                    const SizedBox(height: 28),
                    LabeledField(
                      label: 'Nombre completo',
                      error: _nameError,
                      child: AppTextField(
                        controller: _nameController,
                        hintText: 'Tu nombre completo',
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const <String>[AutofillHints.name],
                        onChanged: (_) {
                          if (_nameError != null) {
                            setState(() => _nameError = null);
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
                        textInputAction: TextInputAction.done,
                        autofillHints: const <String>[
                          AutofillHints.newPassword,
                        ],
                        onChanged: (_) {
                          if (_passwordError != null) {
                            setState(() => _passwordError = null);
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
