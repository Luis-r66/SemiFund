/// Texto legible para las notas de una release de GitHub.
///
/// El cuerpo de la release llega en Markdown y en la tarjeta de actualización
/// se mostraba tal cual (`##`, `**`, viñetas). Aquí se reduce a texto plano
/// sin romper el contenido: se conservan las líneas y se quitan las marcas.
library;

final RegExp _encabezado = RegExp(r'^\s{0,3}#{1,6}\s*');
final RegExp _vineta = RegExp(r'^\s{0,3}[-*+]\s+');
final RegExp _cita = RegExp(r'^\s{0,3}>\s?');
final RegExp _enlace = RegExp(r'\[([^\]]*)\]\([^)]*\)');
final RegExp _imagen = RegExp(r'!\[([^\]]*)\]\([^)]*\)');
final RegExp _enfasis = RegExp(r'(\*{1,3}|_{1,3}|~~|`)');

String notasEnTextoPlano(String notas) {
  if (notas.trim().isEmpty) return '';

  final List<String> lineas = <String>[];
  for (final String cruda in notas.split('\n')) {
    String linea = cruda.replaceAll('\r', '');
    // Un separador horizontal no aporta nada al resumen.
    if (RegExp(r'^\s{0,3}([-*_])(\s*\1){2,}\s*$').hasMatch(linea)) {
      continue;
    }
    linea = linea
        .replaceAllMapped(_imagen, (Match m) => m.group(1) ?? '')
        .replaceAllMapped(_enlace, (Match m) => m.group(1) ?? '')
        .replaceAll(_encabezado, '')
        .replaceAll(_vineta, '')
        .replaceAll(_cita, '')
        .replaceAll(_enfasis, '');
    lineas.add(linea.trimRight());
  }

  // Colapsa los saltos repetidos que dejan las secciones del Markdown.
  final String texto = lineas.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return texto.trim();
}
