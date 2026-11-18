import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../core/utils/json_utils.dart';
import '../models/document_template.dart';

const String docxMimeType =
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
const String xlsxDocumentMimeType =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// Plantillas de documentos del profesor. El servidor llena el archivo y lo
/// devuelve como descarga; la app solo lo comparte o lo guarda.
class DocumentsService {
  DocumentsService(this._api);

  final ApiClient _api;

  Future<List<DocumentTemplate>> listar() async {
    final dynamic data = await _api.get('/documents/templates');
    return asList(data).map(DocumentTemplate.fromJson).toList();
  }

  Future<DocumentTags> catalogo() async {
    final dynamic data = await _api.get('/documents/tags');
    return DocumentTags.fromJson(data);
  }

  Future<DocumentTemplate> subir({
    required Uint8List bytes,
    required String filename,
    required String nombre,
  }) async {
    final dynamic data = await _api.postMultipart(
      '/documents/templates',
      bytes: bytes,
      filename: filename,
      contentType: _mimePara(filename),
      field: 'archivo',
      fields: <String, dynamic>{'nombre': nombre},
    );
    return DocumentTemplate.fromJson(data);
  }

  Future<DocumentTemplate> reemplazar(
    String id, {
    required Uint8List bytes,
    required String filename,
  }) async {
    final dynamic data = await _api.putMultipart(
      '/documents/templates/$id',
      bytes: bytes,
      filename: filename,
      contentType: _mimePara(filename),
      field: 'archivo',
    );
    return DocumentTemplate.fromJson(data);
  }

  Future<void> eliminar(String id) async {
    await _api.delete('/documents/templates/$id');
  }

  Future<GeneratedDocument> generar(
    DocumentTemplate plantilla, {
    Map<String, dynamic> datos = const <String, dynamic>{},
  }) async {
    final String mime = plantilla.esExcel ? xlsxDocumentMimeType : docxMimeType;
    final Response<List<int>> response = await _api.postForBytes(
      '/documents/templates/${plantilla.id}/generate',
      data: datos,
      accept: mime,
    );
    final String? disposition = response.headers.value('content-disposition');
    final String extension = plantilla.esExcel ? 'xlsx' : 'docx';
    return GeneratedDocument(
      bytes: Uint8List.fromList(response.data ?? const <int>[]),
      filename: _nombreDeCabecera(disposition) ?? 'documento.$extension',
    );
  }

  String _mimePara(String filename) {
    return filename.toLowerCase().endsWith('.xlsx')
        ? xlsxDocumentMimeType
        : docxMimeType;
  }

  String? _nombreDeCabecera(String? disposition) {
    if (disposition == null || disposition.isEmpty) return null;
    final RegExpMatch? extendido = RegExp(
      r"filename\*=UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(disposition);
    if (extendido != null) {
      try {
        return Uri.decodeComponent(extendido.group(1)!);
      } catch (_) {
        return extendido.group(1);
      }
    }
    final RegExpMatch? simple = RegExp(r'filename="?([^";]+)"?')
        .firstMatch(disposition);
    return simple?.group(1);
  }
}
