import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/contribution.dart';
import '../../models/member.dart';
import '../../providers/members_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/buttons.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/section_label.dart';
import '../../widgets/status_badge.dart';

class MemberDetailScreen extends StatefulWidget {
  const MemberDetailScreen({super.key, required this.memberId});

  final String memberId;

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  Member? _member;
  List<Contribution> _history = <Contribution>[];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final DashboardService reads = context.read<DashboardService>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<dynamic> results = await Future.wait<dynamic>(
        <Future<dynamic>>[
          reads.member(widget.memberId),
          reads.contributions(memberId: widget.memberId),
        ],
      );
      if (!mounted) return;
      setState(() {
        _member = results[0] as Member;
        _history = results[1] as List<Contribution>;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleActive(Member member) async {
    final MembersProvider members = context.read<MembersProvider>();
    if (member.activo) {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: const Text('Desactivar integrante'),
          content: Text(
            '${member.nombre} dejará de aparecer como integrante activo. Su historial se conserva.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Desactivar'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _busy = true);
    try {
      if (member.activo) {
        await members.deactivate(member.id);
      } else {
        await members.reactivate(member.id);
      }
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTreasurer = context.watch<SessionProvider>().isTesorero;
    final Member? member = _member;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AppTopBar(title: 'Integrante', onBack: () => context.pop()),
            Expanded(
              child: _loading && member == null
                  ? const LoadingView()
                  : member == null
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: ErrorBanner(
                        message: _error ?? 'No se encontró el integrante.',
                        onRetry: _load,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: <Widget>[
                        if (_error != null) ...<Widget>[
                          ErrorBanner(message: _error!, onRetry: _load),
                          const SizedBox(height: 12),
                        ],
                        Center(
                          child: MemberAvatar(
                            name: member.nombre,
                            initialsOverride: member.initials,
                            size: 72,
                            dim: !member.activo,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          member.nombre,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.h2,
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: StatusBadge.active(active: member.activo),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.line),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: _Fact(
                                    label: member.programLabel,
                                    value: member.programa,
                                  ),
                                ),
                                const VerticalDivider(
                                  width: 1,
                                  color: AppColors.line,
                                ),
                                SizedBox(
                                  width: 110,
                                  child: _Fact(
                                    label: 'Semestre',
                                    value: member.semesterLabel,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (member.esCuentaVinculada) ...<Widget>[
                          const SizedBox(height: 10),
                          Text(
                            'Los datos académicos se editan desde el perfil de la cuenta.',
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.ink3,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        const SectionLabel('Historial de aportes'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.line),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: _history.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  child: Text(
                                    'Aún no registra aportes.',
                                    style: AppTextStyles.small.copyWith(
                                      color: AppColors.ink3,
                                    ),
                                  ),
                                )
                              : Column(
                                  children: <Widget>[
                                    for (
                                      int i = 0;
                                      i < _history.length;
                                      i++
                                    ) ...<Widget>[
                                      if (i > 0) const Divider(height: 1),
                                      _HistoryRow(contribution: _history[i]),
                                    ],
                                  ],
                                ),
                        ),
                      ],
                    ),
            ),
            if (member != null && isTreasurer)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: Row(
                  children: <Widget>[
                    if (!member.esCuentaVinculada) ...<Widget>[
                      Expanded(
                        child: SecondaryButton(
                          label: 'Editar',
                          onPressed: _busy
                              ? null
                              : () async {
                                  await context.push(
                                    '/members/${member.id}/edit',
                                  );
                                  if (mounted) await _load();
                                },
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: DangerButton(
                        label: member.activo ? 'Desactivar' : 'Reactivar',
                        onPressed: _busy ? null : () => _toggleActive(member),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: AppTextStyles.tiny.copyWith(color: AppColors.ink3),
          ),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.bodySemibold),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.contribution});

  final Contribution contribution;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  formatMonth(contribution.mes),
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  formatCop(contribution.monto),
                  style: AppTextStyles.moneyTiny.copyWith(
                    color: AppColors.ink2,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge.contribution(contribution),
        ],
      ),
    );
  }
}
