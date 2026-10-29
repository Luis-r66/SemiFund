import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/membership_account.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/section_label.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AccountsProvider>().load();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AccountsProvider accounts = context.watch<AccountsProvider>();
    final SessionProvider session = context.watch<SessionProvider>();
    final String? myUserId = session.user?.id;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AppTopBar(title: 'Cuentas', onBack: () => context.pop()),
            Expanded(
              child: RefreshIndicator(
                onRefresh: accounts.load,
                color: AppColors.ink,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: <Widget>[
                    if (accounts.error != null) ...<Widget>[
                      ErrorBanner(
                        message: accounts.error!,
                        onRetry: accounts.load,
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (accounts.loading && accounts.accounts.isEmpty)
                      const SizedBox(height: 360, child: LoadingView())
                    else ...<Widget>[
                      SectionLabel(
                        'Solicitudes pendientes · ${accounts.pending.length}',
                      ),
                      if (accounts.pending.isEmpty)
                        _Hint('No hay solicitudes pendientes.')
                      else
                        for (final MembershipAccount account
                            in accounts.pending)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PendingCard(
                              account: account,
                              busy: accounts.isBusy(account.id),
                              onApprove: () =>
                                  _run(() => accounts.approve(account)),
                              onReject: () =>
                                  _run(() => accounts.reject(account)),
                            ),
                          ),
                      const SizedBox(height: 22),
                      SectionLabel(
                        'Integrantes con cuenta · ${accounts.members.length}',
                      ),
                      for (final MembershipAccount account in accounts.members)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _MemberCard(
                            account: account,
                            isMe: account.usuario?.id == myUserId,
                            treasurerCount: accounts.activeTreasurers,
                            busy: accounts.isBusy(account.id),
                            onSetTreasurer: (bool value) => _run(
                              () =>
                                  accounts.setTreasurer(account, value: value),
                            ),
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

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Text(
        text,
        style: AppTextStyles.small.copyWith(color: AppColors.ink3),
      ),
    );
  }
}

String _displayName(MembershipAccount account) {
  return account.usuario?.nombre.isNotEmpty == true
      ? account.usuario!.nombre
      : 'Usuario sin datos';
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.account,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final MembershipAccount account;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final String name = _displayName(account);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              MemberAvatar(name: name, size: 44, light: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      style: AppTextStyles.bodySemibold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      account.usuario?.email ?? '',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.ink3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (account.fechaSolicitud != null)
                Text(
                  relativeDays(account.fechaSolicitud),
                  style: AppTextStyles.tiny.copyWith(color: AppColors.ink3),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.bad,
                    side: const BorderSide(color: Color(0x4DC62F2F)),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Rechazar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : onApprove,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: AppColors.paper,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Aprobar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.account,
    required this.isMe,
    required this.treasurerCount,
    required this.busy,
    required this.onSetTreasurer,
  });

  final MembershipAccount account;
  final bool isMe;
  final int treasurerCount;
  final bool busy;
  final ValueChanged<bool> onSetTreasurer;

  @override
  Widget build(BuildContext context) {
    final String name = _displayName(account);
    final bool isTreasurer = account.esTesorero;
    final bool cannotRemove = isTreasurer && treasurerCount <= 1;

    final String actionLabel = isTreasurer
        ? 'Quitar tesorero'
        : 'Hacer tesorero';
    final VoidCallback? action = busy || cannotRemove
        ? null
        : () => onSetTreasurer(!isTreasurer);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              MemberAvatar(name: name, size: 44, dim: !isTreasurer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text.rich(
                      TextSpan(
                        text: name,
                        style: AppTextStyles.bodySemibold,
                        children: <TextSpan>[
                          if (isMe)
                            TextSpan(
                              text: ' (tú)',
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.ink2,
                              ),
                            ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      account.usuario?.email ?? '',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.ink3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _RoleChip(isTreasurer: isTreasurer),
            ],
          ),
          ...<Widget>[
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    cannotRemove ? 'Debe haber al menos un tesorero' : '',
                    style: AppTextStyles.tiny.copyWith(color: AppColors.bad),
                  ),
                ),
                TextButton(
                  onPressed: action,
                  style: TextButton.styleFrom(
                    foregroundColor: isTreasurer
                        ? AppColors.bad
                        : AppColors.ink,
                    disabledForegroundColor: AppColors.ink3,
                  ),
                  child: Text(actionLabel),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.isTreasurer});

  final bool isTreasurer;

  @override
  Widget build(BuildContext context) {
    final Color background = isTreasurer ? AppColors.okSoft : AppColors.mist;
    final Color foreground = isTreasurer ? AppColors.ok : AppColors.ink2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isTreasurer ? 'Tesorero' : 'Integrante',
        style: AppTextStyles.tinySemibold.copyWith(color: foreground),
      ),
    );
  }
}
