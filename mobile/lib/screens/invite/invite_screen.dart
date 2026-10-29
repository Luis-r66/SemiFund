import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../providers/invitation_provider.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_view.dart';

class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<InvitationProvider>().load();
    });
  }

  Future<void> _copy(String code, {String message = 'Código copiado'}) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _share(String code, String name) async {
    final Size size = MediaQuery.of(context).size;
    final Rect origin = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 1,
      height: 1,
    );
    final String text = 'Únete a $name en SemiFund con el código $code.';
    try {
      final ShareResult result = await SharePlus.instance.share(
        ShareParams(text: text, sharePositionOrigin: origin),
      );
      if (result.status == ShareResultStatus.unavailable) {
        await _copy(
          code,
          message: 'Compartir no está disponible. Código copiado.',
        );
      }
    } catch (_) {
      await _copy(
        code,
        message: 'Compartir no está disponible. Código copiado.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final InvitationProvider invitation = context.watch<InvitationProvider>();
    final String? code = invitation.code;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AppTopBar(
              title: 'Invitar integrantes',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: <Widget>[
                  if (invitation.error != null) ...<Widget>[
                    ErrorBanner(
                      message: invitation.error!,
                      onRetry: invitation.load,
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (invitation.loading && code == null)
                    const SizedBox(height: 360, child: LoadingView())
                  else if (code != null) ...<Widget>[
                    _CodeCard(
                      code: formatInviteCode(code),
                      semilleroName: invitation.semilleroName ?? '',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _copy(code),
                            icon: const Icon(LucideIcons.copy, size: 17),
                            label: const Text('Copiar'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.ink,
                              foregroundColor: AppColors.paper,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _share(
                              code,
                              invitation.semilleroName ?? 'SemiFund',
                            ),
                            icon: const Icon(LucideIcons.share2, size: 17),
                            label: const Text('Compartir'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.ink,
                              side: const BorderSide(color: AppColors.line),
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    Text('CÓMO FUNCIONA', style: AppTextStyles.label),
                    const SizedBox(height: 12),
                    const _Step(
                      number: 1,
                      text: 'Comparte el código por WhatsApp o en persona.',
                    ),
                    const SizedBox(height: 12),
                    const _Step(
                      number: 2,
                      text: 'El integrante crea su cuenta y se une con el código.',
                    ),
                    const SizedBox(height: 12),
                    const _Step(
                      number: 3,
                      text: 'Apruebas su solicitud en Cuentas.',
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton.icon(
                        onPressed: invitation.rotating
                            ? null
                            : () => context.read<InvitationProvider>().rotate(),
                        icon: const Icon(LucideIcons.refreshCw, size: 16),
                        label: Text(
                          invitation.rotating
                              ? 'Rotando código...'
                              : 'Rotar código',
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.code, required this.semilleroName});

  final String code;
  final String semilleroName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: <Widget>[
          Text(
            'Código del semillero',
            style: AppTextStyles.smallMedium.copyWith(color: AppColors.ink2),
          ),
          const SizedBox(height: 14),
          FittedBox(
            child: Text(
              code,
              style: AppTextStyles.moneyLarge.copyWith(letterSpacing: 3),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            semilleroName,
            textAlign: TextAlign.center,
            style: AppTextStyles.small.copyWith(color: AppColors.ink3),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.mist,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: AppTextStyles.tinySemibold.copyWith(color: AppColors.ink2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.small.copyWith(color: AppColors.ink2),
          ),
        ),
      ],
    );
  }
}
