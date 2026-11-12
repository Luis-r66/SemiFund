import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/layout/app_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/audit_entry.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_view.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  List<AuditEntry> _entries = <AuditEntry>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<AuditEntry> entries = await context
          .read<DashboardService>()
          .auditLog();
      if (!mounted) return;
      setState(() => _entries = entries);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _when(DateTime? date) {
    if (date == null) return '';
    final DateTime local = date.toLocal();
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '${formatShortDate(local)} · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: AppContent(
          child: Column(
            children: <Widget>[
              AppTopBar(title: 'Actividad', onBack: () => context.pop()),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.ink,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: <Widget>[
                      if (_error != null) ...<Widget>[
                        ErrorBanner(message: _error!, onRetry: _load),
                        const SizedBox(height: 12),
                      ],
                      if (_loading && _entries.isEmpty)
                        const SizedBox(height: 360, child: LoadingView())
                      else if (_entries.isEmpty)
                        const EmptyState(
                          icon: LucideIcons.history,
                          title: 'Sin actividad',
                          message: 'Aquí aparecerán los cambios del semillero.',
                        )
                      else
                        for (final AuditEntry entry in _entries)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.paper,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    entry.titulo,
                                    style: AppTextStyles.bodySemibold,
                                  ),
                                  if (entry.detalle != null) ...<Widget>[
                                    const SizedBox(height: 2),
                                    Text(
                                      entry.detalle!,
                                      style: AppTextStyles.small.copyWith(
                                        color: AppColors.ink2,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Text(
                                    '${entry.usuario} · ${_when(entry.creadoEn)}',
                                    style: AppTextStyles.tiny.copyWith(
                                      color: AppColors.ink3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
