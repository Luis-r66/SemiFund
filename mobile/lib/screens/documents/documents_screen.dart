import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/layout/app_layout.dart';
import '../../core/navigation/volver.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/input_formatters.dart';
import '../../models/document_template.dart';
import '../../providers/documents_provider.dart';
import '../../services/documents_service.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/buttons.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/form_controls.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/section_label.dart';

const int _maxPlantillaBytes = 10 * 1024 * 1024;

/// Documentos del profesor: sube su formato Word o Excel y la app lo llena
/// con los datos del semillero. El archivo generado se descarga; no se guarda.
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  bool _subiendo = false;
  bool _generando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final DocumentsProvider provider = context.read<DocumentsProvider>();
      provider.load(force: true);
      provider.cargarCatalogo();
    });
  }

  void _aviso(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<PlatformFile?> _elegirPlantilla() async {
    final PlatformFile? file = await FilePicker.pickFile(
      dialogTitle: 'Elige tu plantilla',
      type: FileType.custom,
      allowedExtensions: <String>['docx', 'xlsx'],
    );
    if (file == null) return null;

    final String ext = file.name.split('.').last.toLowerCase();
    if (ext != 'docx' && ext != 'xlsx') {
      _aviso('La plantilla debe ser un archivo .docx o .xlsx.');
      return null;
    }
    final int? tamano = await file.length();
    if (tamano != null && tamano > _maxPlantillaBytes) {
      _aviso('La plantilla supera el límite de 10 MB.');
      return null;
    }
    return file;
  }

  Future<String?> _pedirNombre(String sugerido) {
    final TextEditingController controller = TextEditingController(
      text: sugerido,
    );
    String? error;
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Nombre de la plantilla'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Así aparecerá en la lista. Puedes cambiarlo cuando quieras '
                    'subiendo el archivo de nuevo.',
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    inputFormatters: <TextInputFormatter>[
                      LengthLimitingTextInputFormatter(80),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Ej. Formato de viáticos',
                      errorText: error,
                    ),
                    onSubmitted: (String value) {
                      final String texto = value.trim();
                      if (texto.isEmpty) {
                        setState(() => error = 'Escribe un nombre.');
                        return;
                      }
                      Navigator.of(dialogContext).pop(texto);
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final String texto = controller.text.trim();
                    if (texto.isEmpty) {
                      setState(() => error = 'Escribe un nombre.');
                      return;
                    }
                    Navigator.of(dialogContext).pop(texto);
                  },
                  child: const Text('Subir'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(controller.dispose);
  }

  Future<void> _subir() async {
    if (_subiendo) return;
    final PlatformFile? file = await _elegirPlantilla();
    if (file == null || !mounted) return;

    final String base = file.name.contains('.')
        ? file.name.substring(0, file.name.lastIndexOf('.'))
        : file.name;
    final String? nombre = await _pedirNombre(base);
    if (nombre == null || !mounted) return;

    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      _aviso('No se pudo leer el archivo seleccionado.');
      return;
    }
    if (bytes.isEmpty) {
      _aviso('El archivo está vacío.');
      return;
    }
    if (!mounted) return;

    final DocumentsProvider provider = context.read<DocumentsProvider>();
    setState(() => _subiendo = true);
    try {
      await provider.subir(bytes: bytes, filename: file.name, nombre: nombre);
      _aviso('Plantilla subida. Ya puedes generar el documento.');
    } on ApiException catch (error) {
      _aviso(error.message);
    } catch (_) {
      _aviso('No se pudo subir la plantilla. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  Future<void> _reemplazar(DocumentTemplate plantilla) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Reemplazar archivo'),
        content: Text(
          'Se cambiará el archivo de "${plantilla.nombre}". El nombre y las '
          'etiquetas se actualizan con el nuevo archivo.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Elegir archivo'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    final PlatformFile? file = await _elegirPlantilla();
    if (file == null || !mounted) return;

    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      _aviso('No se pudo leer el archivo seleccionado.');
      return;
    }
    if (bytes.isEmpty) {
      _aviso('El archivo está vacío.');
      return;
    }
    if (!mounted) return;

    final DocumentsProvider provider = context.read<DocumentsProvider>();
    setState(() => _subiendo = true);
    try {
      await provider.reemplazar(plantilla, bytes: bytes, filename: file.name);
      _aviso('Archivo reemplazado.');
    } on ApiException catch (error) {
      _aviso(error.message);
    } catch (_) {
      _aviso('No se pudo reemplazar el archivo. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  Future<void> _eliminar(DocumentTemplate plantilla) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Eliminar plantilla'),
        content: Text(
          'Se eliminará "${plantilla.nombre}". Los documentos ya generados no '
          'se guardan en la app, así que no se pierde ninguno.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.bad,
              foregroundColor: AppColors.paper,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    setState(() => _subiendo = true);
    try {
      await context.read<DocumentsProvider>().eliminar(plantilla);
      _aviso('Plantilla eliminada.');
    } on ApiException catch (error) {
      _aviso(error.message);
    } catch (_) {
      _aviso('No se pudo eliminar la plantilla. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  bool _necesitaDatos(DocumentTemplate plantilla) {
    return plantilla.usaPrefijo('viaje.') ||
        plantilla.usaPrefijo('documento.') ||
        plantilla.usa('periodo.ciudad') ||
        plantilla.usaPrefijo('periodo.') ||
        plantilla.usaPrefijo('gastos') ||
        plantilla.usa('#gastos') ||
        plantilla.usaPrefijo('movimientos') ||
        plantilla.usa('#movimientos') ||
        plantilla.usaPrefijo('totales.');
  }

  Future<void> _generar(DocumentTemplate plantilla) async {
    if (_generando) return;

    Map<String, dynamic> datos = const <String, dynamic>{};
    if (_necesitaDatos(plantilla)) {
      final Map<String, dynamic>? entrada =
          await showModalBottomSheet<Map<String, dynamic>>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            showDragHandle: true,
            builder: (BuildContext sheetContext) =>
                _GenerateSheet(plantilla: plantilla),
          );
      if (entrada == null || !mounted) return;
      datos = entrada;
    }

    setState(() => _generando = true);
    try {
      final GeneratedDocument documento = await context
          .read<DocumentsProvider>()
          .generar(plantilla, datos: datos);
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[
            XFile.fromData(
              documento.bytes,
              mimeType: plantilla.esExcel ? xlsxDocumentMimeType : docxMimeType,
              name: documento.filename,
            ),
          ],
          downloadFallbackEnabled: true,
        ),
      );
    } on ApiException catch (error) {
      _aviso(error.message);
    } catch (_) {
      _aviso('No se pudo generar el documento. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final DocumentsProvider provider = context.watch<DocumentsProvider>();

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: AppContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppTopBar(
                title: 'Documentos',
                onBack: AppLayout.isDesktop(context)
                    ? null
                    : () => volver(context),
                trailing: IconButton(
                  tooltip: 'Actualizar',
                  onPressed: provider.loading
                      ? null
                      : () => provider.load(force: true),
                  icon: const Icon(LucideIcons.refreshCw, size: 20),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.load(force: true),
                  color: AppColors.ink,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    children: <Widget>[
                      if (provider.error != null) ...<Widget>[
                        ErrorBanner(
                          message: provider.error!,
                          onRetry: () => provider.load(force: true),
                        ),
                        const SizedBox(height: 14),
                      ],
                      _UploadCard(
                        busy: _subiendo,
                        onUpload: _subiendo ? null : _subir,
                      ),
                      const SizedBox(height: 28),
                      const SectionLabel('Plantillas del semillero'),
                      if (provider.loading && provider.templates.isEmpty)
                        const SizedBox(height: 260, child: LoadingView())
                      else if (provider.templates.isEmpty)
                        EmptyState(
                          icon: LucideIcons.fileText,
                          title: 'Aún no hay plantillas',
                          message:
                              'Sube el formato que te pide la universidad. '
                              'Puede ser un Word (.docx) o un Excel (.xlsx) con '
                              'las etiquetas que aparecen abajo.',
                        )
                      else
                        for (final DocumentTemplate plantilla
                            in provider.templates)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _TemplateTile(
                              plantilla: plantilla,
                              busy: _subiendo || _generando,
                              onGenerate: () => _generar(plantilla),
                              onReplace: () => _reemplazar(plantilla),
                              onDelete: () => _eliminar(plantilla),
                            ),
                          ),
                      const SizedBox(height: 28),
                      _TagsCard(catalogo: provider.catalogo),
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

class _UploadCard extends StatelessWidget {
  const _UploadCard({required this.busy, required this.onUpload});

  final bool busy;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.paper,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.sparkles,
                  size: 20,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tus formatos, llenos por la app',
                  style: AppTextStyles.h4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Sube el archivo que te pide la universidad y escribe las '
            'etiquetas donde van los datos: {{semillero.nombre}}, '
            '{{profesor.nombre}}, {{#gastos}}…{{/gastos}}. SemiFund lo llena '
            'y tú lo descargas para enviarlo.',
            style: AppTextStyles.small.copyWith(
              color: AppColors.ink2,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: PrimaryButton(
              label: 'Subir plantilla',
              icon: LucideIcons.upload,
              loading: busy,
              onPressed: onUpload,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Word (.docx) o Excel (.xlsx) · máximo 10 MB',
            style: AppTextStyles.tiny.copyWith(color: AppColors.ink3),
          ),
        ],
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.plantilla,
    required this.busy,
    required this.onGenerate,
    required this.onReplace,
    required this.onDelete,
  });

  final DocumentTemplate plantilla;
  final bool busy;
  final VoidCallback onGenerate;
  final VoidCallback onReplace;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final List<String> detalles = <String>[
      plantilla.tipoLabel,
      if (plantilla.pesoLabel.isNotEmpty) plantilla.pesoLabel,
      '${plantilla.etiquetas.length} '
          '${plantilla.etiquetas.length == 1 ? 'etiqueta' : 'etiquetas'}',
    ];

    return Material(
      color: AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: busy ? null : onGenerate,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.mist,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  plantilla.esExcel
                      ? LucideIcons.fileSpreadsheet
                      : LucideIcons.fileText,
                  size: 22,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      plantilla.nombre,
                      style: AppTextStyles.bodySemibold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detalles.join(' · '),
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.ink2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plantilla.updatedAt == null
                          ? 'Genera el documento cuando lo necesites'
                          : 'Actualizada ${formatShortDate(plantilla.updatedAt)}',
                      style: AppTextStyles.tiny.copyWith(color: AppColors.ink3),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opciones de la plantilla',
                enabled: !busy,
                onSelected: (String opcion) {
                  switch (opcion) {
                    case 'generar':
                      onGenerate();
                      break;
                    case 'reemplazar':
                      onReplace();
                      break;
                    case 'eliminar':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'generar',
                    child: Text('Generar documento'),
                  ),
                  PopupMenuItem<String>(
                    value: 'reemplazar',
                    child: Text(
                      plantilla.esExcel
                          ? 'Reemplazar Excel'
                          : 'Reemplazar Word',
                    ),
                  ),
                  if (plantilla.puedeEliminar) ...<PopupMenuEntry<String>>[
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'eliminar',
                      child: Text('Eliminar plantilla'),
                    ),
                  ],
                ],
                icon: const Icon(
                  LucideIcons.moreVertical,
                  size: 20,
                  color: AppColors.ink2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagsCard extends StatelessWidget {
  const _TagsCard({required this.catalogo});

  final DocumentTags? catalogo;

  @override
  Widget build(BuildContext context) {
    final DocumentTags? tags = catalogo;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: const Icon(
            LucideIcons.info,
            size: 20,
            color: AppColors.ink2,
          ),
          title: Text(
            'Etiquetas disponibles',
            style: AppTextStyles.bodySemibold,
          ),
          subtitle: Text(
            'Escríbelas entre {{ }} en tu archivo',
            style: AppTextStyles.small.copyWith(color: AppColors.ink2),
          ),
          children: <Widget>[
            if (tags == null)
              Text(
                'Cargando el catálogo…',
                style: AppTextStyles.small.copyWith(color: AppColors.ink3),
              )
            else ...<Widget>[
              for (final MapEntry<String, List<DocumentField>> grupo
                  in tags.grupos.entries) ...<Widget>[
                _GroupTitle(_tituloGrupo(grupo.key)),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    for (final DocumentField campo in grupo.value)
                      _TagChip(
                        etiqueta: '{{${campo.clave}}}',
                        descripcion: campo.descripcion,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              const _GroupTitle('Bloques que se repiten'),
              Text(
                'Abres el bloque, escribes los campos una vez y lo cierras. '
                'La app lo repite por cada registro. Dentro del bloque puedes '
                'usar {{campo}} o {{bloque.campo}}.',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.ink2,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              for (final DocumentBlock bloque in tags.bloques)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _TagChip(
                        etiqueta:
                            '{{#${bloque.nombre}}} … {{/${bloque.nombre}}}',
                        descripcion: bloque.descripcion,
                        destacado: true,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: <Widget>[
                          for (final DocumentField campo in bloque.campos)
                            _TagChip(
                              etiqueta: '{{${campo.clave}}}',
                              descripcion: campo.descripcion,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _tituloGrupo(String clave) {
    switch (clave) {
      case 'semillero':
        return 'Semillero';
      case 'profesor':
        return 'Profesor';
      case 'periodo':
        return 'Periodo';
      case 'totales':
        return 'Totales';
      case 'viaje':
        return 'Viaje o comisión';
      case 'documento':
        return 'Documento';
      case 'firma':
        return 'Firma';
      default:
        return 'Otros datos';
    }
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texto.toUpperCase(),
        style: AppTextStyles.label.copyWith(color: AppColors.ink2),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.etiqueta,
    required this.descripcion,
    this.destacado = false,
  });

  final String etiqueta;
  final String descripcion;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: descripcion,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: destacado ? AppColors.ink : AppColors.mist,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          etiqueta,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.2,
            color: destacado ? AppColors.paper : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _GenerateSheet extends StatefulWidget {
  const _GenerateSheet({required this.plantilla});

  final DocumentTemplate plantilla;

  @override
  State<_GenerateSheet> createState() => _GenerateSheetState();
}

class _GenerateSheetState extends State<_GenerateSheet> {
  final List<String> _meses = monthOptions(DateTime.now());
  late String? _mes = currentMonth(DateTime.now());
  final TextEditingController _inicio = TextEditingController();
  final TextEditingController _fin = TextEditingController();
  final TextEditingController _ciudades = TextEditingController();
  final TextEditingController _objeto = TextEditingController();
  final TextEditingController _valor = TextEditingController();
  final TextEditingController _hora = TextEditingController();
  final TextEditingController _lugar = TextEditingController();
  final TextEditingController _observaciones = TextEditingController();
  final TextEditingController _ciudad = TextEditingController();
  String? _error;

  DocumentTemplate get _p => widget.plantilla;

  bool get _necesitaMes =>
      _p.usaPrefijo('periodo.') ||
      _p.usaPrefijo('gastos') ||
      _p.usa('#gastos') ||
      _p.usaPrefijo('movimientos') ||
      _p.usa('#movimientos') ||
      _p.usaPrefijo('totales.');
  bool get _necesitaInicio => _p.usa('viaje.inicio');
  bool get _necesitaFin => _p.usa('viaje.fin');
  bool get _necesitaCiudades => _p.usa('viaje.ciudades');
  bool get _necesitaObjeto => _p.usa('viaje.objeto');
  bool get _necesitaValor =>
      _p.usa('viaje.valorEntregado') || _p.usa('totales.diferencia');
  bool get _necesitaHora => _p.usa('documento.hora');
  bool get _necesitaLugar => _p.usa('documento.lugar');
  bool get _necesitaObservaciones => _p.usa('documento.observaciones');
  bool get _necesitaCiudad => _p.usa('periodo.ciudad');

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[
      _inicio,
      _fin,
      _ciudades,
      _objeto,
      _valor,
      _hora,
      _lugar,
      _observaciones,
      _ciudad,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _confirmar() {
    if (_necesitaMes && _mes == null) {
      setState(() => _error = 'Selecciona el mes del documento.');
      return;
    }
    final Map<String, dynamic> datos = <String, dynamic>{};
    if (_necesitaMes && _mes != null) datos['mes'] = _mes;
    void agregar(String clave, TextEditingController controller) {
      final String valor = controller.text.trim();
      if (valor.isNotEmpty) datos[clave] = valor;
    }

    if (_necesitaInicio) agregar('inicio', _inicio);
    if (_necesitaFin) agregar('fin', _fin);
    if (_necesitaCiudades) agregar('ciudades', _ciudades);
    if (_necesitaObjeto) agregar('objeto', _objeto);
    if (_necesitaHora) agregar('hora', _hora);
    if (_necesitaLugar) agregar('lugar', _lugar);
    if (_necesitaObservaciones) agregar('observaciones', _observaciones);
    if (_necesitaCiudad) agregar('ciudad', _ciudad);
    if (_necesitaValor) {
      final double valor = parseMoney(_valor.text);
      if (valor > 0) datos['valorEntregado'] = valor;
    }
    Navigator.of(context).pop(datos);
  }

  @override
  Widget build(BuildContext context) {
    final bool hayCampos =
        _necesitaMes ||
        _necesitaInicio ||
        _necesitaFin ||
        _necesitaCiudades ||
        _necesitaObjeto ||
        _necesitaValor ||
        _necesitaHora ||
        _necesitaLugar ||
        _necesitaObservaciones ||
        _necesitaCiudad;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Generar documento', style: AppTextStyles.h2),
            const SizedBox(height: 4),
            Text(
              widget.plantilla.nombre,
              style: AppTextStyles.small.copyWith(color: AppColors.ink2),
            ),
            const SizedBox(height: 8),
            Text(
              'Completa solo los datos que esta plantilla necesita. Lo demás '
              'sale del semillero.',
              style: AppTextStyles.small.copyWith(
                color: AppColors.ink2,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            if (!hayCampos)
              Text(
                'Esta plantilla se llena completamente con los datos del '
                'semillero. Pulsa Generar para descargarla.',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.ink2,
                  height: 1.4,
                ),
              ),
            if (_necesitaMes)
              LabeledField(
                label: 'Mes del documento',
                child: SelectField<String>(
                  value: _mes,
                  items: _meses,
                  labelOf: formatMonth,
                  hintText: 'Selecciona el mes',
                  onChanged: (String? value) => setState(() {
                    _mes = value;
                    _error = null;
                  }),
                ),
              ),
            if (_necesitaInicio)
              LabeledField(
                label: 'Fecha de inicio',
                child: AppTextField(
                  controller: _inicio,
                  hintText: 'Ej. 05/07/2026',
                  textInputAction: TextInputAction.next,
                ),
              ),
            if (_necesitaFin)
              LabeledField(
                label: 'Fecha de fin',
                child: AppTextField(
                  controller: _fin,
                  hintText: 'Ej. 08/07/2026',
                  textInputAction: TextInputAction.next,
                ),
              ),
            if (_necesitaCiudades)
              LabeledField(
                label: 'Ciudades y países',
                child: AppTextField(
                  controller: _ciudades,
                  hintText: 'Ej. Bogotá, Colombia',
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                ),
              ),
            if (_necesitaObjeto)
              LabeledField(
                label: 'Objeto del viaje',
                child: AppTextField(
                  controller: _objeto,
                  hintText: 'Ej. Reunión del semillero',
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  textInputAction: TextInputAction.next,
                ),
              ),
            if (_necesitaValor)
              LabeledField(
                label: 'Valor entregado (opcional)',
                child: MoneyField(controller: _valor),
              ),
            if (_necesitaHora)
              LabeledField(
                label: 'Hora',
                child: AppTextField(
                  controller: _hora,
                  hintText: 'Ej. 8:00 a. m.',
                  textInputAction: TextInputAction.next,
                ),
              ),
            if (_necesitaLugar)
              LabeledField(
                label: 'Lugar',
                child: AppTextField(
                  controller: _lugar,
                  hintText: 'Ej. Bogotá D.C.',
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                ),
              ),
            if (_necesitaCiudad)
              LabeledField(
                label: 'Ciudad',
                child: AppTextField(
                  controller: _ciudad,
                  hintText: 'Ej. Bogotá D.C.',
                  inputFormatters: simpleTextFormatters,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                ),
              ),
            if (_necesitaObservaciones)
              LabeledField(
                label: 'Observaciones',
                child: AppTextField(
                  controller: _observaciones,
                  hintText: 'Texto libre para el documento',
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _confirmar(),
                ),
              ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                _error!,
                style: AppTextStyles.small.copyWith(color: AppColors.bad),
              ),
              const SizedBox(height: 12),
            ],
            PrimaryButton(
              label: 'Generar y descargar',
              icon: LucideIcons.download,
              onPressed: _confirmar,
            ),
          ],
        ),
      ),
    );
  }
}
