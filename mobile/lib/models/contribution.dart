import '../core/utils/json_utils.dart';

enum ContributionStatus {
  pendiente('pendiente', 'pending', 'Pendiente'),
  pagado('pagado', 'paid', 'Pagado'),
  vencido('vencido', 'overdue', 'Vencido');

  const ContributionStatus(this.apiValue, this.queryValue, this.label);

  final String apiValue;
  final String queryValue;
  final String label;

  static ContributionStatus fromApi(dynamic value) {
    final String normalized = asString(value).toLowerCase();
    for (final ContributionStatus status in ContributionStatus.values) {
      if (status.apiValue == normalized || status.queryValue == normalized) {
        return status;
      }
    }
    return ContributionStatus.pendiente;
  }
}

class Contribution {
  const Contribution({
    required this.id,
    required this.integranteId,
    required this.monto,
    required this.mes,
    required this.concepto,
    required this.estado,
    this.fechaPago,
    this.createdAt,
  });

  final String id;
  final String integranteId;
  final double monto;
  final String mes;
  final String concepto;
  final ContributionStatus estado;
  final DateTime? fechaPago;
  final DateTime? createdAt;

  bool get isPaid => estado == ContributionStatus.pagado;

  factory Contribution.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    return Contribution(
      id: asString(map['id'] ?? map['_id']),
      integranteId: asString(map['integranteId']),
      monto: asDouble(map['monto']),
      mes: asString(map['mes']),
      concepto: asString(map['concepto']),
      estado: ContributionStatus.fromApi(map['estado']),
      fechaPago: asDate(map['fechaPago']),
      createdAt: asDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'integranteId': integranteId,
    'monto': monto,
    'mes': mes,
    'concepto': concepto,
    'estado': estado.apiValue,
    'fechaPago': fechaPago?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
  };

  Contribution copyWith({
    String? id,
    String? integranteId,
    double? monto,
    String? mes,
    String? concepto,
    ContributionStatus? estado,
    DateTime? fechaPago,
    DateTime? createdAt,
  }) {
    return Contribution(
      id: id ?? this.id,
      integranteId: integranteId ?? this.integranteId,
      monto: monto ?? this.monto,
      mes: mes ?? this.mes,
      concepto: concepto ?? this.concepto,
      estado: estado ?? this.estado,
      fechaPago: fechaPago ?? this.fechaPago,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
