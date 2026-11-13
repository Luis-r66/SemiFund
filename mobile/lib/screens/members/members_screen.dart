import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/layout/app_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/member.dart';
import '../../providers/members_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/form_controls.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/pager.dart';
import '../../widgets/status_badge.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MembersProvider>().load();
    });
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<MembersProvider>().load(query: _search.text);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MembersProvider members = context.watch<MembersProvider>();
    final bool isTreasurer = context.watch<SessionProvider>().isTesorero;
    final bool buscando = members.query.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: AppContent(
          child: Column(
            children: <Widget>[
              AppTopBar(
                title: 'Integrantes',
                onBack: AppLayout.isDesktop(context)
                    ? null
                    : () => context.pop(),
                trailing: isTreasurer
                    ? RoundAddButton(
                        onPressed: () => context.push('/members/new'),
                      )
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: SearchField(
                  controller: _search,
                  hintText: 'Buscar integrante',
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: members.load,
                  color: AppColors.ink,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: <Widget>[
                      if (members.error != null) ...<Widget>[
                        ErrorBanner(
                          message: members.error!,
                          onRetry: members.load,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (members.loading && members.members.isEmpty)
                        const SizedBox(height: 360, child: LoadingView())
                      else if (members.members.isEmpty)
                        EmptyState(
                          icon: buscando
                              ? LucideIcons.search
                              : LucideIcons.users,
                          title: buscando
                              ? 'Sin resultados'
                              : 'Aún no hay integrantes',
                          message: buscando
                              ? 'No encontramos integrantes para "${_search.text.trim()}".'
                              : 'Cuando agregues integrantes aparecerán aquí.',
                        )
                      else ...<Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                          child: Text(
                            '${members.total} ${members.total == 1 ? 'integrante' : 'integrantes'}'
                                .toUpperCase(),
                            style: AppTextStyles.label,
                          ),
                        ),
                        for (final Member member in members.members)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _MemberTile(
                              member: member,
                              onTap: () =>
                                  context.push('/members/${member.id}'),
                            ),
                          ),
                        Pager(
                          page: members.page,
                          pages: members.pages,
                          loading: members.loadingMore,
                          onPage: members.goToPage,
                          onLoadMore: members.loadMore,
                        ),
                      ],
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

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.onTap});

  final Member member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              MemberAvatar(
                name: member.nombre,
                initialsOverride: member.initials,
                dim: !member.activo,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      member.nombre,
                      style: AppTextStyles.bodySemibold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.esProfesor
                          ? '${member.programa} · Docente'
                          : '${member.programa} · ${member.semesterLabel} sem.',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.ink2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!member.esCuentaVinculada) ...<Widget>[
                      const SizedBox(height: 5),
                      Row(
                        children: <Widget>[
                          const Icon(
                            LucideIcons.userX,
                            size: 13,
                            color: AppColors.ink3,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Sin cuenta',
                            style: AppTextStyles.tiny.copyWith(
                              color: AppColors.ink3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge.active(active: member.activo),
            ],
          ),
        ),
      ),
    );
  }
}
