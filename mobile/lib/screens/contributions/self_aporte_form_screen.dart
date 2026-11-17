import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/layout/app_layout.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../providers/contributions_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/buttons.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/form_controls.dart';
import '../../widgets/success_check.dart';

/// Aporte propio del integrante: viaje, materiales u otro destino.
/// Se envía con comprobante y queda reportado para que el tesorero lo apruebe.
class SelfAporteFormScreen extends StatefulWidget {
  const SelfAporteFormScreen({super.key, this.hoy});

  final DateTime? hoy;

  @override
  State<SelfAporteFormScreen> createState() => _SelfAporteFormScreenState();
}

class _SelfAporteFormScreenState extends State<SelfAporteFormScreen> {
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _concept = TextEditingController();
  final TextEditingController _reference = TextEditingController();
  late final List<String> _months;

  String? _month;
  PlatformFile? _file;
  Uint8List? _bytes;
  String? _contentType;
  bool _reading = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final DateTime hoy = widget.hoy ?? DateTime.now();
    _months = monthOptions(hoy);
    _month = currentMonth(hoy);
    _amount.addListener(() => setState(() {}));
    _concept.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amount.dispose();
    _concept.dispose();
    _reference.dispose();
    super.dispose();
  }

  double get _montoValue => parseMoney(_amount.text);

  bool get _canSave =>
      _month != null &&
      _montoValue > 0 &&
      _concept.text.trim().isNotEmpty &&
      _bytes != null &&
      !_reading &&
      !_saving;

  String? _contentTypeFor(String filename) {
    final String ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
    }
    return null;
  }

  Future<void> _pick() async {
    if (_reading) return;
    final PlatformFile? file = await FilePicker.pickFile(
      dialogTitle: 'Elige el comprobante',
      type: FileType.custom,
      allowedExtensions: <String>['jpg', 'jpeg', 'png', 'webp', 'pdf'],
    );
    if (file == null || !mounted) return;

    final String? contentType = _contentTypeFor(file.name);
    if (contentType == null) {
      setState(() => _error = 'El comprobante debe ser JPG, PNG, WebP o PDF.');
      return;
    }

    setState(() => _reading = true);
    try {
      final Uint8List bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty) {
        setState(() => _error = 'El archivo está vacío.');
        return;
      }
      if (bytes.length > AppConfig.maxComprobanteBytes) {
        setState(() => _error = 'El comprobante supera el límite de 5 MB.');
        return;
      }
      setState(() {
        _file = file;
        _bytes = bytes;
        _contentType = contentType;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo leer el archivo seleccionado.');
      }
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  Future<void> _save() async {
    if (!_canSave) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<ContributionsProvider>().createSelf(
        monto: _montoValue,
        mes: _month!,
        concepto: _concept.text.trim(),
        referencia: _reference.text.trim().isEmpty
            ? null
            : _reference.text.trim(),
        comprobanteBytes: _bytes!,
        comprobanteNombre: _file!.name,
        comprobanteTipo: _contentType!,
      );
      if (!mounted) return;
      await showSuccessCheck(context, message: 'Aporte reportado');
      if (!mounted) return;
      context.pop();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isImage = (_contentType ?? '').startsWith('image/');
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: AppContent(
          maxWidth: AppLayout.formMaxWidth,
          child: Column(
            children: <Widget>[
              AppTopBar(title: 'Nuevo aporte', onBack: () => context.pop()),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Registra tu aporte para un viaje, materiales u otro destino. '
                        'Queda reportado y el tesorero lo aprueba.',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.ink2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      LabeledField(
                        label: 'Mes',
                        child: SelectField<String>(
                          value: _month,
                          items: _months,
                          labelOf: formatMonth,
                          hintText: 'Selecciona el mes',
                          onChanged: (String? value) =>
                              setState(() => _month = value),
                        ),
                      ),
                      LabeledField(
                        label: 'Monto (COP)',
                        child: MoneyField(controller: _amount),
                      ),
                      LabeledField(
                        label: 'Concepto',
                        child: AppTextField(
                          controller: _concept,
                          hintText: 'Ej. Viaje a Medellín',
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      LabeledField(
                        label: 'Referencia (opcional)',
                        child: AppTextField(
                          controller: _reference,
                          hintText: 'Número de transacción',
                          textInputAction: TextInputAction.done,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Comprobante obligatorio',
                        style: AppTextStyles.smallSemibold,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'JPG, PNG, WebP o PDF · máximo 5 MB',
                        style: AppTextStyles.tiny.copyWith(
                          color: AppColors.ink3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_bytes == null)
                        OutlinedButton.icon(
                          onPressed: _reading ? null : _pick,
                          icon: const Icon(LucideIcons.upload, size: 18),
                          label: Text(
                            _reading ? 'Leyendo…' : 'Adjuntar comprobante',
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.mist,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                isImage
                                    ? LucideIcons.image
                                    : LucideIcons.fileText,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _file!.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.small,
                                ),
                              ),
                              TextButton(
                                onPressed: _reading ? null : _pick,
                                child: const Text('Cambiar'),
                              ),
                            ],
                          ),
                        ),
                      if (_error != null) ...<Widget>[
                        const SizedBox(height: 12),
                        ErrorBanner(message: _error!),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: PrimaryButton(
                  label: 'Reportar aporte',
                  loading: _saving,
                  onPressed: _canSave ? _save : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
