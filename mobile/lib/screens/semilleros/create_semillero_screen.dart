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

class CreateSemilleroScreen extends StatefulWidget {
  const CreateSemilleroScreen({super.key});

  @override
  State<CreateSemilleroScreen> createState() => _CreateSemilleroScreenState();
}

class _CreateSemilleroScreenState extends State<CreateSemilleroScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _nameController.text.trim().isNotEmpty && !_loading;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await context.read<SessionProvider>().createSemillero(
        _nameController.text.trim(),
      );
      if (!mounted) return;
      final SessionProvider session = context.read<SessionProvider>();
      if (session.hasActiveSemillero) {
        context.go('/home');
      } else {
        context.go('/semilleros');
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo crear el semillero.');
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
            AppTopBar(title: 'Crear semillero', onBack: () => context.pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    LabeledField(
                      label: 'Nombre del semillero',
                      child: AppTextField(
                        controller: _nameController,
                        hintText: 'Ej. Semillero de Desarrollo Móvil',
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.mist,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              LucideIcons.shieldCheck,
                              size: 18,
                              color: AppColors.ink2,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: 'Quedarás como ',
                                style: AppTextStyles.small.copyWith(
                                  color: AppColors.ink2,
                                ),
                                children: const <TextSpan>[
                                  TextSpan(
                                    text: 'tesorero',
                                    style: TextStyle(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '. Podrás invitar integrantes con un código de 8 caracteres y aprobar sus cuentas.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: 16),
                      ErrorBanner(message: _error!),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: PrimaryButton(
                label: 'Crear semillero',
                loading: _loading,
                onPressed: _canSubmit ? _submit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
