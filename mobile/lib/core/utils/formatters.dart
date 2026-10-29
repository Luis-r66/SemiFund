import 'package:intl/intl.dart';

final NumberFormat _decimal = NumberFormat.decimalPattern('es_CO');

const List<String> _monthNames = <String>[
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

const List<String> _monthShortNames = <String>[
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

String formatCop(num value) => '\$${_decimal.format(value)}';

String formatMonth(String? yearMonth) {
  if (yearMonth == null || yearMonth.trim().isEmpty) return '—';
  final List<String> parts = yearMonth.split('-');
  if (parts.length < 2) return yearMonth;
  final int? year = int.tryParse(parts[0]);
  final int? month = int.tryParse(parts[1]);
  if (year == null || month == null || month < 1 || month > 12) {
    return yearMonth;
  }
  return '${_monthNames[month - 1]} $year';
}

String formatShortDate(DateTime? date) {
  if (date == null) return '—';
  final DateTime local = date.toLocal();
  return '${local.day} ${_monthShortNames[local.month - 1]} ${local.year}';
}

String formatDayMonth(DateTime date) {
  final DateTime local = date.toLocal();
  return '${local.day} ${_monthShortNames[local.month - 1]}';
}

String capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

String initials(String name) => initialsFromParts(fullName: name);

/// Iniciales a partir de nombres/apellidos separados o, como respaldo,
/// de un nombre completo antiguo. Con 3+ palabras usa la primera y la
/// penúltima para intentar saltar el segundo nombre.
String initialsFromParts({
  String? nombres,
  String? apellidos,
  String? fullName,
}) {
  final String nombresLimpios = (nombres ?? '').trim();
  final String apellidosLimpios = (apellidos ?? '').trim();
  if (nombresLimpios.isNotEmpty && apellidosLimpios.isNotEmpty) {
    return _firstLetter(nombresLimpios) + _firstLetter(apellidosLimpios);
  }

  final List<String> parts = (fullName ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((String part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return _firstLetter(parts.first);
  if (parts.length == 2) return _firstLetter(parts[0]) + _firstLetter(parts[1]);
  return _firstLetter(parts[0]) + _firstLetter(parts[parts.length - 2]);
}

String _firstLetter(String value) => value.substring(0, 1).toUpperCase();

String firstName(String name) {
  final String trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.split(RegExp(r'\s+')).first;
}

String roleLabel({required bool esTesorero, required String estado}) {
  if (estado == 'pendiente') return 'Pendiente';
  if (estado == 'rechazado') return 'Rechazado';
  if (estado == 'inactivo') return 'Inactivo';
  return esTesorero ? 'Tesorero' : 'Integrante';
}

/// Formato de entrada de montos con separador de miles (es-CO), sin símbolo.
String formatThousands(num value) => _decimal.format(value);

/// Convierte el texto de un campo de monto (ej. "520.000") a número.
double parseMoney(String text) {
  final String digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.isEmpty ? 0 : double.parse(digits);
}

/// Meses YYYY-MM alrededor de [reference]: [back] meses atrás y [forward] adelante.
List<String> monthOptions(DateTime reference, {int back = 6, int forward = 1}) {
  final List<String> options = <String>[];
  for (int offset = -back; offset <= forward; offset++) {
    final DateTime date = DateTime(reference.year, reference.month + offset);
    options.add(_yearMonth(date));
  }
  return options;
}

/// Mes actual en formato YYYY-MM.
String currentMonth(DateTime reference) => _yearMonth(reference);

String _yearMonth(DateTime date) {
  final String month = date.month.toString().padLeft(2, '0');
  return '${date.year}-$month';
}

/// Categorías fijas de gasto (la app; el backend acepta texto libre).
const List<String> expenseCategories = <String>[
  'Infraestructura',
  'Eventos',
  'Difusión',
  'Software',
  'Materiales',
  'Otros',
];

/// Fecha relativa breve, ej. "Hace 2 días", "Hoy", "Ayer".
String relativeDays(DateTime? date, {DateTime? now}) {
  if (date == null) return '';
  final DateTime reference = now ?? DateTime.now();
  final DateTime local = date.toLocal();
  final int days = DateTime(
    reference.year,
    reference.month,
    reference.day,
  ).difference(DateTime(local.year, local.month, local.day)).inDays;
  if (days <= 0) return 'Hoy';
  if (days == 1) return 'Ayer';
  return 'Hace $days días';
}

/// Código de invitación legible: "DSW7K2QX" -> "DSW7 · K2QX".
String formatInviteCode(String code) {
  if (code.length != 8) return code;
  return '${code.substring(0, 4)} · ${code.substring(4)}';
}
