import '../core/utils/json_utils.dart';

class Balance {
  const Balance({
    required this.totalAportado,
    required this.totalGastado,
    required this.saldoDisponible,
  });

  final double totalAportado;
  final double totalGastado;
  final double saldoDisponible;

  static const Balance empty = Balance(
    totalAportado: 0,
    totalGastado: 0,
    saldoDisponible: 0,
  );

  factory Balance.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    return Balance(
      totalAportado: asDouble(map['totalAportado']),
      totalGastado: asDouble(map['totalGastado']),
      saldoDisponible: asDouble(map['saldoDisponible']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'totalAportado': totalAportado,
    'totalGastado': totalGastado,
    'saldoDisponible': saldoDisponible,
  };
}
