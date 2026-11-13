import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../core/layout/app_layout.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/app_notification.dart';
import '../providers/notifications_provider.dart';
import '../providers/session_provider.dart';
import 'empty_state.dart';

/// Campanita con contador. Solo se muestra en la web: la app Android y la PWA
/// de iPhone congelada conservan su interfaz.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  Timer? _timer;
  String? _loadedFor;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      if (context.read<SessionProvider>().activeSemillero == null) return;
      context.read<NotificationsProvider>().refreshUnread();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _abrir(BuildContext context) {
    final NotificationsProvider provider = context
        .read<NotificationsProvider>();
    final String? id = context.read<SessionProvider>().activeSemillero?.id;
    if (id != null) provider.load(id);

    if (AppLayout.isDesktop(context)) {
      showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) => Dialog(
          backgroundColor: AppColors.paper,
          insetPadding: const EdgeInsets.all(24),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430, maxHeight: 560),
            child: const _NotificationsPanel(),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.paper,
      builder: (BuildContext sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
          ),
          child: const _NotificationsPanel(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SessionProvider session = context.watch<SessionProvider>();
    final NotificationsProvider notifications = context
        .watch<NotificationsProvider>();
    final String? semilleroId = session.activeSemillero?.id;

    // Carga perezosa al entrar y al cambiar de semillero.
    if (semilleroId != null && semilleroId != _loadedFor) {
      _loadedFor = semilleroId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<NotificationsProvider>().load(semilleroId);
      });
    }

    if (semilleroId == null) return const SizedBox.shrink();
    final int unread = notifications.unread;

    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () => _abrir(context),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.line),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(LucideIcons.bell, size: 18),
          ),
          if (unread > 0)
            Positioned(
              right: -2,
              top: -2,
              child: IgnorePointer(
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.paper, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: AppTextStyles.tiny.copyWith(
                      color: AppColors.paper,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationsPanel extends StatelessWidget {
  const _NotificationsPanel();

  @override
  Widget build(BuildContext context) {
    final NotificationsProvider provider = context
        .watch<NotificationsProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
          child: Row(
            children: <Widget>[
              Expanded(child: Text('Notificaciones', style: AppTextStyles.h4)),
              if (provider.unread > 0)
                TextButton(
                  onPressed: provider.markAllRead,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.ink2,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text('Marcar leídas'),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.line),
        Flexible(
          child: provider.loading && provider.items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : provider.items.isEmpty
              ? const EmptyState(
                  icon: LucideIcons.bell,
                  title: 'Sin notificaciones',
                  message: 'Aquí verás los pagos y cuotas de tu semillero.',
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: provider.items.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: AppColors.line),
                  itemBuilder: (BuildContext context, int index) {
                    final AppNotification item = provider.items[index];
                    return _NotificationTile(
                      item: item,
                      onTap: () => provider.markRead(item),
                    );
                  },
                ),
        ),
        if (provider.hasMore)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                onPressed: provider.loadingMore ? null : provider.loadMore,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: const BorderSide(color: AppColors.line),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: AppTextStyles.smallSemibold,
                ),
                child: provider.loadingMore
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Ver anteriores'),
              ),
            ),
          ),
        if (!provider.loading) ...<Widget>[
          const Divider(height: 1, color: AppColors.line),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 12, 6),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Avisos por correo',
                        style: AppTextStyles.smallSemibold.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Te escribimos cuando hay movimiento en el semillero.',
                        style: AppTextStyles.tiny.copyWith(
                          color: AppColors.ink3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: provider.emailAvisos,
                  onChanged: provider.savingPreference
                      ? null
                      : provider.setEmailAvisos,
                  activeThumbColor: AppColors.paper,
                  activeTrackColor: AppColors.ink,
                  inactiveThumbColor: AppColors.paper,
                  inactiveTrackColor: AppColors.ink3,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  IconData get _icon {
    switch (item.tipo) {
      case 'abono_aprobado':
        return LucideIcons.check;
      case 'abono_rechazado':
        return LucideIcons.x;
      case 'cuota_nueva':
        return LucideIcons.receipt;
      case 'invitacion_aceptada':
        return LucideIcons.userPlus;
      default:
        return LucideIcons.clock;
    }
  }

  String get _hace {
    final DateTime? fecha = item.createdAt;
    if (fecha == null) return '';
    final Duration diff = DateTime.now().difference(fecha);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    final String dia = fecha.day.toString().padLeft(2, '0');
    final String mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.leida
          ? AppColors.paper
          : AppColors.mist.withValues(alpha: 0.55),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 13, 16, 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.mist,
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, size: 16, color: AppColors.ink2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            item.titulo,
                            style: AppTextStyles.smallSemibold.copyWith(
                              color: AppColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!item.leida) ...<Widget>[
                          const SizedBox(width: 8),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.ink,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.mensaje,
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.ink2,
                      ),
                    ),
                    if (_hace.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 5),
                      Text(
                        _hace,
                        style: AppTextStyles.tiny.copyWith(
                          color: AppColors.ink3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inserta la campanita solo en la web.
class WebNotificationBell extends StatelessWidget {
  const WebNotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();
    return const NotificationBell();
  }
}
