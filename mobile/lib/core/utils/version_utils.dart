/// Comparación de versiones tipo `1.4.0` o `v1.4.0+8`.
library;

/// Limpia el prefijo `v`, el build (`+8`) y los sufijos de preestreno.
String normalizarVersion(String value) {
  String version = value.trim().toLowerCase();
  if (version.startsWith('v')) version = version.substring(1);
  final int plus = version.indexOf('+');
  if (plus >= 0) version = version.substring(0, plus);
  final int guion = version.indexOf('-');
  if (guion >= 0) version = version.substring(0, guion);
  return version;
}

List<int> _partes(String value) {
  return normalizarVersion(value).split('.').map((String parte) {
    final RegExpMatch? match = RegExp(r'^\d+').firstMatch(parte);
    return match == null ? 0 : int.parse(match.group(0)!);
  }).toList();
}

/// Devuelve negativo si [a] es menor que [b], positivo si es mayor y 0 si son iguales.
int compararVersiones(String a, String b) {
  final List<int> pa = _partes(a);
  final List<int> pb = _partes(b);
  final int largo = pa.length > pb.length ? pa.length : pb.length;
  for (int i = 0; i < largo; i++) {
    final int va = i < pa.length ? pa[i] : 0;
    final int vb = i < pb.length ? pb[i] : 0;
    if (va != vb) return va.compareTo(vb);
  }
  return 0;
}
