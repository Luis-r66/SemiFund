import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/document_template.dart';
import '../services/documents_service.dart';

class DocumentsProvider extends ChangeNotifier {
  DocumentsProvider(this._service);

  final DocumentsService _service;

  List<DocumentTemplate> _templates = <DocumentTemplate>[];
  DocumentTags? _catalogo;
  bool _loading = false;
  bool _busy = false;
  String? _error;

  List<DocumentTemplate> get templates => List.unmodifiable(_templates);
  DocumentTags? get catalogo => _catalogo;
  bool get loading => _loading;
  bool get busy => _busy;
  String? get error => _error;

  Future<void> load({bool force = false}) async {
    if (_loading) return;
    if (!force && _templates.isNotEmpty) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _templates = await _service.listar();
    } on ApiException catch (error) {
      _error = error.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> cargarCatalogo() async {
    if (_catalogo != null) return;
    try {
      _catalogo = await _service.catalogo();
    } on ApiException {
      // El catálogo es una ayuda: si falla, la pantalla sigue funcionando.
    }
    notifyListeners();
  }

  Future<DocumentTemplate> subir({
    required Uint8List bytes,
    required String filename,
    required String nombre,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final DocumentTemplate creada = await _service.subir(
        bytes: bytes,
        filename: filename,
        nombre: nombre,
      );
      _templates = <DocumentTemplate>[..._templates, creada];
      return creada;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<DocumentTemplate> reemplazar(
    DocumentTemplate plantilla, {
    required Uint8List bytes,
    required String filename,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final DocumentTemplate actualizada = await _service.reemplazar(
        plantilla.id,
        bytes: bytes,
        filename: filename,
      );
      _templates = _templates
          .map(
            (DocumentTemplate item) =>
                item.id == actualizada.id ? actualizada : item,
          )
          .toList();
      return actualizada;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> eliminar(DocumentTemplate plantilla) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _service.eliminar(plantilla.id);
      _templates = _templates
          .where((DocumentTemplate item) => item.id != plantilla.id)
          .toList();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<GeneratedDocument> generar(
    DocumentTemplate plantilla, {
    Map<String, dynamic> datos = const <String, dynamic>{},
  }) {
    return _service.generar(plantilla, datos: datos);
  }
}
