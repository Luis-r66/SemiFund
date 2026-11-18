import 'dart:typed_data';

import '../core/utils/json_utils.dart';

/// Plantilla .docx o .xlsx que sube un profesor. Se llena con los datos del
/// semillero y se descarga; nunca se guarda una copia del archivo generado.
class DocumentTemplate {
  const DocumentTemplate({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.bytes,
    this.etiquetas = const <String>[],
    this.puedeEliminar = false,
    this.updatedAt,
  });

  final String id;
  final String nombre;

  /// `docx` o `xlsx`.
  final String tipo;
  final int? bytes;
  final List<String> etiquetas;
  final bool puedeEliminar;
  final DateTime? updatedAt;

  bool get esWord => tipo == 'docx';
  bool get esExcel => tipo == 'xlsx';

  String get tipoLabel => esWord ? 'Word' : 'Excel';

  String get pesoLabel {
    final int total = bytes ?? 0;
    if (total <= 0) return '';
    if (total >= 1024 * 1024) {
      return '${(total / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(total / 1024).ceil()} KB';
  }

  /// Etiquetas repetibles que usa la plantilla, sin las marcas de cierre.
  List<String> get bloques => etiquetas
      .where((String tag) => tag.startsWith('#'))
      .map((String tag) => tag.substring(1).trim())
      .toList();

  bool usa(String etiqueta) => etiquetas.contains(etiqueta);

  bool usaPrefijo(String prefijo) =>
      etiquetas.any((String etiqueta) => etiqueta.startsWith(prefijo));

  factory DocumentTemplate.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    return DocumentTemplate(
      id: asString(map['id'] ?? map['_id']),
      nombre: asString(map['nombre']),
      tipo: asString(map['tipo']),
      bytes: map['bytes'] == null ? null : asInt(map['bytes']),
      etiquetas: asList(map['etiquetas'])
          .map((dynamic item) => asString(item))
          .where((String item) => item.isNotEmpty)
          .toList(),
      puedeEliminar: asBool(map['puedeEliminar']),
      updatedAt: asDate(map['updatedAt'] ?? map['createdAt']),
    );
  }
}

/// Una etiqueta simple que la app llena sola, por ejemplo `semillero.nombre`.
class DocumentField {
  const DocumentField({required this.clave, required this.descripcion});

  final String clave;
  final String descripcion;

  factory DocumentField.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    return DocumentField(
      clave: asString(map['clave']),
      descripcion: asString(map['descripcion']),
    );
  }
}

/// Un bloque que se repite por cada integrante, gasto o movimiento.
class DocumentBlock {
  const DocumentBlock({
    required this.nombre,
    required this.descripcion,
    required this.campos,
  });

  final String nombre;
  final String descripcion;
  final List<DocumentField> campos;

  factory DocumentBlock.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    return DocumentBlock(
      nombre: asString(map['nombre']),
      descripcion: asString(map['descripcion']),
      campos: asList(map['campos']).map(DocumentField.fromJson).toList(),
    );
  }
}

/// Catálogo de etiquetas que el servidor acepta en una plantilla.
class DocumentTags {
  const DocumentTags({required this.simples, required this.bloques});

  final List<DocumentField> simples;
  final List<DocumentBlock> bloques;

  factory DocumentTags.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    return DocumentTags(
      simples: asList(map['simples']).map(DocumentField.fromJson).toList(),
      bloques: asList(map['bloques']).map(DocumentBlock.fromJson).toList(),
    );
  }

  /// Agrupa las etiquetas simples por su primer tramo (semillero, profesor…).
  Map<String, List<DocumentField>> get grupos {
    final Map<String, List<DocumentField>> agrupadas =
        <String, List<DocumentField>>{};
    for (final DocumentField campo in simples) {
      final String grupo = campo.clave.contains('.')
          ? campo.clave.split('.').first
          : 'otros';
      agrupadas.putIfAbsent(grupo, () => <DocumentField>[]).add(campo);
    }
    return agrupadas;
  }
}

/// Archivo ya lleno que se comparte o descarga; no se conserva en la app.
class GeneratedDocument {
  const GeneratedDocument({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}
