import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/semillero_membership.dart';
import '../providers/session_provider.dart';
import 'status_badge.dart';

Future<void> showSemilleroSwitcher(
  BuildContext context,
  SessionProvider session,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.paper,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      final List<SemilleroMembership> active = session.activeMemberships;

      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Cambiar semillero', style: AppTextStyles.h3),
              const SizedBox(height: 4),
              Text(
                'Elige el semillero que quieres gestionar.',
                style: AppTextStyles.small.copyWith(color: AppColors.ink2),
              ),
              const SizedBox(height: 16),
              if (active.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.mist,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'No tienes semilleros activos en este momento.',
                    style: AppTextStyles.small.copyWith(color: AppColors.ink2),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: active.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext itemContext, int index) {
                      final SemilleroMembership membership = active[index];
                      final bool selected =
                          session.activeSemillero?.semilleroId ==
                          membership.semilleroId;
                      return Material(
                        color: selected ? AppColors.mist : AppColors.paper,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppColors.line),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () async {
                            await session.selectSemillero(membership);
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        membership.nombre,
                                        style: AppTextStyles.bodySemibold,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      StatusBadge.membership(membership),
                                    ],
                                  ),
                                ),
                                if (selected)
                                  const Icon(
                                    LucideIcons.check,
                                    size: 19,
                                    color: AppColors.ok,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  context.go('/semilleros');
                },
                child: const Text('Ver todos mis semilleros'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
