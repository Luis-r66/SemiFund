import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/semillero_membership.dart';
import '../../providers/session_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/buttons.dart';
import '../../widgets/error_banner.dart';

class JoinSemilleroScreen extends StatefulWidget {
  const JoinSemilleroScreen({super.key});

  @override
  State<JoinSemilleroScreen> createState() => _JoinSemilleroScreenState();
}

class _JoinSemilleroScreenState extends State<JoinSemilleroScreen> {
  final TextEditingController _codeController = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _codeController.text.length == 8 && !_loading;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final SessionProvider session = context.read<SessionProvider>();
      final result = await session.joinSemillero(_codeController.text);
      if (!mounted) return;

      final SemilleroMembership membership =
          session.membershipFor(result.semilleroId) ??
          SemilleroMembership(
            id: result.semilleroId,
            semilleroId: result.semilleroId,
            nombre: result.semilleroNombre,
            esTesorero: false,
            estado: result.estado,
            miembros: 0,
          );

      context.pushReplacement('/semilleros/pending', extra: membership);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo enviar la solicitud.');
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
            AppTopBar(title: 'Unirme con código', onBack: () => context.pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Pídele al tesorero el código de invitación de tu semillero.',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.ink2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    LabeledField(
                      label: 'Código del semillero',
                      child: CodeField(
                        controller: _codeController,
                        onChanged: (_) {
                          if (_error != null) setState(() => _error = null);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: <Widget>[
                          Text(
                            'Solo mayúsculas y números',
                            style: AppTextStyles.tiny.copyWith(
                              color: AppColors.ink3,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_codeController.text.length}/8',
                            style: AppTextStyles.tinyMedium.copyWith(
                              color: AppColors.ink3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: 18),
                      ErrorBanner(message: _error!),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: PrimaryButton(
                label: 'Unirme',
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
