import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/import_result.dart';
import '../../widgets/buttons.dart';
import '../../widgets/section_label.dart';

/// Vista previa de la plantilla Excel. No se escribe nada hasta confirmar.
class ExcelImportSheet extends StatefulWidget {
  const ExcelImportSheet({
    super.key,
    required this.preview,
    required this.onConfirm,
  });

  final ImportPreview preview;
  final Future<ImportResult> Function() onConfirm;

  @override
  State<ExcelImportSheet> createState() => _ExcelImportSheetState();
}

class _ExcelImportSheetState extends State<ExcelImportSheet> {
  bool _confirming = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() {
      _confirming = true;
      _error = null;
    });
    try {
      final ImportResult result = await widget.onConfirm();
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ImportPreview preview = widget.preview;
    final ImportTotals totals = preview.totales;
    final bool puedeConfirmar = totals.puedeConfirmar && !_confirming;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text('Revisar importación', style: AppTextStyles.h3),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: _confirming
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Revisa lo que se va a crear. Las filas con ID ya existen y se omiten.',
                style: AppTextStyles.small.copyWith(color: AppColors.ink2),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _Metric(
                      label: 'Nuevos',
                      value: totals.nuevos,
                      color: AppColors.ok,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Metric(
                      label: 'Omitidos',
                      value: totals.omitidos,
                      color: AppColors.ink2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Metric(
                      label: 'Errores',
                      value: totals.errores,
                      color: totals.errores > 0
                          ? AppColors.bad
                          : AppColors.ink3,
                    ),
                  ),
                ],
              ),
              if (totals.errores > 0) ...<Widget>[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.badSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x33C62F2F)),
                  ),
                  child: Text(
                    'Corrige las filas marcadas en rojo y vuelve a cargar el archivo. No se guardará nada hasta que no haya errores.',
                    style: AppTextStyles.small.copyWith(color: AppColors.bad),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const SectionLabel('Detalle por fila'),
              const SizedBox(height: 4),
              Flexible(
                child: preview.filas.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No hay filas nuevas en el archivo.',
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.ink3,
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: preview.filas.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 12, color: AppColors.line),
                        itemBuilder: (BuildContext context, int index) {
                          return _ImportRowTile(row: preview.filas[index]);
                        },
                      ),
              ),
              if (preview.filasTruncadas) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'La vista previa muestra solo las primeras filas. La importación valida el archivo completo.',
                  style: AppTextStyles.tiny.copyWith(color: AppColors.ink3),
                ),
              ],
              if (_error != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: AppTextStyles.small.copyWith(color: AppColors.bad),
                ),
              ],
              const SizedBox(height: 16),
              PrimaryButton(
                label: totals.nuevos == 1
                    ? 'Confirmar 1 registro nuevo'
                    : 'Confirmar ${totals.nuevos} registros nuevos',
                onPressed: puedeConfirmar ? _confirm : null,
                loading: _confirming,
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Solo se crearán las filas sin ID. No se modifica nada existente.',
                  style: AppTextStyles.tiny.copyWith(color: AppColors.ink3),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: AppTextStyles.tiny.copyWith(color: AppColors.ink3),
          ),
          const SizedBox(height: 2),
          Text(
            '$value',
            style: AppTextStyles.moneySmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _ImportRowTile extends StatelessWidget {
  const _ImportRowTile({required this.row});

  final ImportRow row;

  @override
  Widget build(BuildContext context) {
    final Color color = row.esError
        ? AppColors.bad
        : row.esNuevo
        ? AppColors.ink
        : AppColors.ink2;
    final IconData icon = row.esError
        ? LucideIcons.circleAlert
        : row.esNuevo
        ? LucideIcons.circleCheck
        : LucideIcons.circleMinus;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${row.hoja} · fila ${row.fila}',
                style: AppTextStyles.tinySemibold.copyWith(
                  color: AppColors.ink3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                row.mensaje,
                style: AppTextStyles.small.copyWith(color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
