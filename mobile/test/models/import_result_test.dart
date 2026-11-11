import 'package:flutter_test/flutter_test.dart';
import 'package:semi_fund/models/import_result.dart';

void main() {
  test('parsea la vista previa de importación', () {
    final ImportPreview preview = ImportPreview.fromJson(<String, dynamic>{
      'totales': <String, dynamic>{
        'nuevos': 3,
        'omitidos': 1,
        'errores': 0,
        'existentes': 12,
      },
      'filasTruncadas': false,
      'filas': <dynamic>[
        <String, dynamic>{
          'hoja': 'Integrantes',
          'fila': 4,
          'estado': 'nuevo',
          'mensaje': 'Carolina Gómez · Ingeniería Industrial',
        },
        <String, dynamic>{
          'hoja': 'Gastos',
          'fila': 3,
          'estado': 'error',
          'mensaje': 'La fecha no puede ser futura.',
        },
      ],
    });

    expect(preview.totales.nuevos, 3);
    expect(preview.totales.omitidos, 1);
    expect(preview.totales.errores, 0);
    expect(preview.totales.existentes, 12);
    expect(preview.totales.puedeConfirmar, isTrue);
    expect(preview.filas, hasLength(2));
    expect(preview.filas.first.esNuevo, isTrue);
    expect(preview.filas.last.esError, isTrue);
    expect(preview.filasTruncadas, isFalse);
  });

  test('no permite confirmar si hay errores o no hay filas nuevas', () {
    const ImportTotals conError = ImportTotals(
      nuevos: 2,
      omitidos: 0,
      errores: 1,
      existentes: 0,
    );
    const ImportTotals sinNuevos = ImportTotals(
      nuevos: 0,
      omitidos: 4,
      errores: 0,
      existentes: 4,
    );

    expect(conError.puedeConfirmar, isFalse);
    expect(sinNuevos.puedeConfirmar, isFalse);
  });

  test('parsea el resultado de la importación', () {
    final ImportResult result = ImportResult.fromJson(<String, dynamic>{
      'creados': <String, dynamic>{
        'integrantes': 1,
        'aportes': 2,
        'abonos': 3,
        'gastos': 1,
      },
      'mensaje': 'Importación completada.',
    });

    expect(result.creados.integrantes, 1);
    expect(result.creados.aportes, 2);
    expect(result.creados.abonos, 3);
    expect(result.creados.gastos, 1);
    expect(result.creados.total, 7);
    expect(result.mensaje, 'Importación completada.');
  });
}
