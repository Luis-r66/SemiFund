import '../core/utils/json_utils.dart';

/// Una fila con algo que contar en la vista previa de importación.
class ImportRow {
  const ImportRow({
    required this.hoja,
    required this.fila,
    required this.estado,
    required this.mensaje,
  });

  final String hoja;
  final int fila;
  final String estado;
  final String mensaje;

  bool get esError => estado == 'error';
  bool get esNuevo => estado == 'nuevo';

  factory ImportRow.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    return ImportRow(
      hoja: asString(map['hoja']),
      fila: asInt(map['fila']),
      estado: asString(map['estado']),
      mensaje: asString(map['mensaje']),
    );
  }
}

class ImportTotals {
  const ImportTotals({
    required this.nuevos,
    required this.omitidos,
    required this.errores,
    required this.existentes,
  });

  final int nuevos;
  final int omitidos;
  final int errores;
  final int existentes;

  static const ImportTotals empty = ImportTotals(
    nuevos: 0,
    omitidos: 0,
    errores: 0,
    existentes: 0,
  );

  factory ImportTotals.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    return ImportTotals(
      nuevos: asInt(map['nuevos']),
      omitidos: asInt(map['omitidos']),
      errores: asInt(map['errores']),
      existentes: asInt(map['existentes']),
    );
  }

  bool get puedeConfirmar => errores == 0 && nuevos > 0;
}

class ImportPreview {
  const ImportPreview({
    required this.totales,
    required this.filas,
    required this.filasTruncadas,
  });

  final ImportTotals totales;
  final List<ImportRow> filas;
  final bool filasTruncadas;

  factory ImportPreview.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    return ImportPreview(
      totales: ImportTotals.fromJson(map['totales']),
      filas: asList(map['filas']).map(ImportRow.fromJson).toList(),
      filasTruncadas: asBool(map['filasTruncadas']),
    );
  }

  List<ImportRow> get errores =>
      filas.where((ImportRow row) => row.esError).toList();

  List<ImportRow> get nuevas =>
      filas.where((ImportRow row) => row.esNuevo).toList();
}

class ImportCreation {
  const ImportCreation({
    required this.integrantes,
    required this.aportes,
    required this.abonos,
    required this.gastos,
  });

  final int integrantes;
  final int aportes;
  final int abonos;
  final int gastos;

  int get total => integrantes + aportes + abonos + gastos;

  factory ImportCreation.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    return ImportCreation(
      integrantes: asInt(map['integrantes']),
      aportes: asInt(map['aportes']),
      abonos: asInt(map['abonos']),
      gastos: asInt(map['gastos']),
    );
  }
}

class ImportResult {
  const ImportResult({required this.creados, required this.mensaje});

  final ImportCreation creados;
  final String mensaje;

  factory ImportResult.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    final ImportCreation creados = ImportCreation.fromJson(map['creados']);
    return ImportResult(
      creados: creados,
      mensaje: asString(
        map['mensaje'],
        fallback: 'Importación completada: ${creados.total} registros nuevos.',
      ),
    );
  }
}
