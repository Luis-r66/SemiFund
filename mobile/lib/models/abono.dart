import '../core/utils/json_utils.dart';

enum AbonoStatus {
  reportado('Reportado'),
  aprobado('Aprobado'),
  rechazado('Rechazado'),
  anulado('Anulado');

  const AbonoStatus(this.label);

  final String label;

  static AbonoStatus fromApi(dynamic value) {
    final String normalized = asString(value).toLowerCase();
    for (final AbonoStatus status in AbonoStatus.values) {
      if (status.name == normalized) return status;
    }
    return AbonoStatus.reportado;
  }
}

class Abono {
  const Abono({
    required this.id,
    required this.monto,
    required this.estado,
    this.fecha,
    this.referencia,
    this.motivo,
  });

  final String id;
  final double monto;
  final AbonoStatus estado;
  final DateTime? fecha;
  final String? referencia;
  final String? motivo;

  factory Abono.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    return Abono(
      id: asString(map['id'] ?? map['_id']),
      monto: asDouble(map['monto']),
      estado: AbonoStatus.fromApi(map['estado']),
      fecha: asDate(map['fecha']),
      referencia: asNullableString(map['referencia']),
      motivo: asNullableString(map['motivo']),
    );
  }
}
