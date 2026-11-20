import 'package:flutter_test/flutter_test.dart';
import 'package:semi_fund/core/utils/notes_utils.dart';

void main() {
  test('quita encabezados, viñetas y énfasis', () {
    const String markdown = '''
## Novedades
- **Cuotas** por integrante
* Aportes con `abonos` parciales
''';
    expect(
      notasEnTextoPlano(markdown),
      'Novedades\nCuotas por integrante\nAportes con abonos parciales',
    );
  });

  test('convierte los enlaces en su texto y quita imágenes', () {
    const String markdown =
        'Ver [la guía](https://ejemplo.com) y ![captura](https://ejemplo.com/a.png)';
    expect(notasEnTextoPlano(markdown), 'Ver la guía y captura');
  });

  test('conserva los saltos de párrafo sin repetirlos', () {
    const String markdown = 'Uno\n\n\n\nDos';
    expect(notasEnTextoPlano(markdown), 'Uno\n\nDos');
  });

  test('un cuerpo vacío devuelve texto vacío', () {
    expect(notasEnTextoPlano('   \n '), '');
  });
}
