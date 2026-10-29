import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/session_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/buttons.dart';
import '../../widgets/error_banner.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _current = TextEditingController();
  final TextEditingController _newPassword = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  bool _saving = false;
  String? _currentError;
  String? _newError;
  String? _confirmError;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final TextEditingController controller in <TextEditingController>[
      _current,
      _newPassword,
      _confirm,
    ]) {
      controller.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _current.dispose();
    _newPassword.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _current.text.isNotEmpty &&
      _newPassword.text.length >= 8 &&
      _confirm.text == _newPassword.text &&
      !_saving;

  Future<void> _save() async {
    setState(() {
      _currentError = _current.text.isEmpty
          ? 'Ingresa tu contraseña actual.'
          : null;
      _newError = _newPassword.text.length < 8
          ? 'La nueva contraseña debe tener al menos 8 caracteres.'
          : null;
      _confirmError = _confirm.text != _newPassword.text
          ? 'Las contraseñas no coinciden.'
          : null;
      _error = null;
    });
    if (_currentError != null || _newError != null || _confirmError != null) {
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<SessionProvider>().changePassword(
        currentPassword: _current.text,
        newPassword: _newPassword.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Contraseña actualizada')));
      context.pop();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No se pudo cambiar la contraseña. Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AppTopBar(title: 'Cambiar contraseña', onBack: () => context.pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Confirma tu contraseña actual y define una nueva.',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.ink2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    LabeledField(
                      label: 'Contraseña actual',
                      error: _currentError,
                      child: PasswordField(
                        controller: _current,
                        hintText: 'Tu contraseña actual',
                        textInputAction: TextInputAction.next,
                        autofillHints: const <String>[AutofillHints.password],
                      ),
                    ),
                    LabeledField(
                      label: 'Nueva contraseña',
                      error: _newError,
                      helper: 'Mínimo 8 caracteres',
                      child: PasswordField(
                        controller: _newPassword,
                        hintText: 'Nueva contraseña',
                        textInputAction: TextInputAction.next,
                        autofillHints: const <String>[
                          AutofillHints.newPassword,
                        ],
                      ),
                    ),
                    LabeledField(
                      label: 'Confirmar nueva contraseña',
                      error: _confirmError,
                      child: PasswordField(
                        controller: _confirm,
                        hintText: 'Repite la nueva contraseña',
                        textInputAction: TextInputAction.done,
                        autofillHints: const <String>[
                          AutofillHints.newPassword,
                        ],
                        onSubmitted: (_) => _save(),
                      ),
                    ),
                    if (_error != null) ErrorBanner(message: _error!),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: PrimaryButton(
                label: 'Guardar contraseña',
                loading: _saving,
                onPressed: _canSave ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
