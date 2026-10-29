import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

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
import '../../widgets/status_badge.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(
      () => setState(() => _query = _search.text.trim().toLowerCase()),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MembersProvider>().load();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Member> _filter(List<Member> members) {
    if (_query.isEmpty) return members;
    return members.where((Member member) {
      return member.nombre.toLowerCase().contains(_query) ||
          member.programa.toLowerCase().contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final MembersProvider members = context.watch<MembersProvider>();
    final bool isTreasurer = context.watch<SessionProvider>().isTesorero;
    final List<Member> visible = _filter(members.members);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AppTopBar(
              title: 'Integrantes',
              onBack: () => context.pop(),
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
                      const EmptyState(
                        icon: LucideIcons.users,
                        title: 'Aún no hay integrantes',
                        message: 'Cuando agregues integrantes aparecerán aquí.',
                      )
                    else ...<Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                        child: Text(
                          '${visible.length} ${visible.length == 1 ? 'integrante' : 'integrantes'}'
                              .toUpperCase(),
                          style: AppTextStyles.label,
                        ),
                      ),
                      if (visible.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'Sin resultados para "${_search.text.trim()}"',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.ink3,
                            ),
                          ),
                        ),
                      for (final Member member in visible)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _MemberTile(
                            member: member,
                            onTap: () => context.push('/members/${member.id}'),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
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
                      '${member.programa} · ${member.semestre}° sem.',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.ink2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
