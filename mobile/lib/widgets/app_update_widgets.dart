import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/app_release.dart';
import '../providers/app_info_provider.dart';
import 'buttons.dart';
import 'section_label.dart';

/// Aviso compacto en Inicio cuando hay una versión nueva.
class UpdateBanner extends StatelessWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final AppInfoProvider info = context.watch<AppInfoProvider>();
    if (!info.showBanner) return const SizedBox.shrink();
    final AppRelease release = info.release!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: <Widget>[
            const Icon(LucideIcons.download, size: 18, color: AppColors.paper),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Versión ${release.version} disponible',
                    style: AppTextStyles.smallSemibold.copyWith(
                      color: AppColors.paper,
                    ),
                  ),
                  if (release.sizeLabel.isNotEmpty)
                    Text(
                      '${release.sizeLabel} · descarga el APK nuevo',
                      style: AppTextStyles.tiny.copyWith(
                        color: AppColors.paper.withValues(alpha: 0.72),
                      ),
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: info.descargar,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.paper,
                textStyle: AppTextStyles.smallSemibold,
              ),
              child: const Text('Descargar'),
            ),
            IconButton(
              onPressed: info.descartar,
              tooltip: 'Ocultar',
              icon: Icon(
                LucideIcons.x,
                size: 16,
                color: AppColors.paper.withValues(alpha: 0.7),
              ),
              constraints: const BoxConstraints.tightFor(width: 34, height: 34),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bloque "Acerca de" del perfil: versión instalada y búsqueda de updates.
class UpdateSection extends StatelessWidget {
  const UpdateSection({super.key});

  Future<void> _buscar(BuildContext context, AppInfoProvider info) async {
    final bool found = await info.buscarAhora();
    if (!context.mounted) return;
    final String message = found
        ? 'Hay una versión nueva: ${info.release!.version}.'
        : info.error ?? 'Tienes la última versión de SemiFund.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final AppInfoProvider info = context.watch<AppInfoProvider>();
    final AppRelease? release = info.release;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionLabel('Acerca de'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: <Widget>[
              _InfoRow(label: 'Versión', value: info.versionLabel),
              const Divider(),
              _InfoRow(label: 'Canal', value: 'GitHub Releases · Android'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SecondaryButton(
          label: info.checking ? 'Consultando...' : 'Buscar actualizaciones',
          onPressed: info.checking ? null : () => _buscar(context, info),
        ),
        if (info.error != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            info.error!,
            style: AppTextStyles.tiny.copyWith(color: AppColors.bad),
          ),
        ],
        if (release != null) ...<Widget>[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      LucideIcons.sparkles,
                      size: 16,
                      color: AppColors.ink,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Versión ${release.version} disponible',
                        style: AppTextStyles.bodySemibold,
                      ),
                    ),
                    if (release.sizeLabel.isNotEmpty)
                      Text(
                        release.sizeLabel,
                        style: AppTextStyles.tiny.copyWith(
                          color: AppColors.ink2,
                        ),
                      ),
                  ],
                ),
                if (release.notes.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    release.notes.trim(),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.ink2,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                PrimaryButton(
                  label: 'Descargar ${release.version}',
                  icon: LucideIcons.download,
                  onPressed: info.descargar,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: AppTextStyles.small.copyWith(color: AppColors.ink2),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.smallSemibold,
            ),
          ),
        ],
      ),
    );
  }
}
