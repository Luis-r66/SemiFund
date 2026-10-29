import '../core/utils/formatters.dart';
import '../core/utils/json_utils.dart';

class Expense {
  const Expense({
    required this.id,
    required this.descripcion,
    required this.categoria,
    required this.monto,
    this.fecha,
  });

  final String id;
  final String descripcion;
  final String categoria;
  final double monto;
  final DateTime? fecha;

  String get categoriaLabel => capitalize(categoria);

  factory Expense.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    return Expense(
      id: asString(map['id'] ?? map['_id']),
      descripcion: asString(map['descripcion']),
      categoria: asString(map['categoria']),
      monto: asDouble(map['monto']),
      fecha: asDate(map['fecha']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'descripcion': descripcion,
    'categoria': categoria,
    'monto': monto,
    'fecha': fecha?.toIso8601String(),
  };
}
