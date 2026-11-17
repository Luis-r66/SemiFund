import '../core/utils/json_utils.dart';

class Balance {
  const Balance({
    required this.totalAportado,
    required this.totalGastado,
    required this.saldoDisponible,
    this.saldoInicial = 0,
  });

  final double totalAportado;
  final double totalGastado;
  final double saldoDisponible;

  /// Dinero que el semillero ya tenía antes de usar la app. No es un aporte.
  final double saldoInicial;

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
      saldoInicial: asDouble(map['saldoInicial']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'totalAportado': totalAportado,
    'totalGastado': totalGastado,
    'saldoDisponible': saldoDisponible,
    'saldoInicial': saldoInicial,
  };
}
