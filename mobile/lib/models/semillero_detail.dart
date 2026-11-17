import '../core/utils/json_utils.dart';

class SemilleroDetail {
  const SemilleroDetail({
    required this.id,
    required this.nombre,
    required this.creadoPor,
    required this.esTesorero,
    this.codigo,
    this.esCreador = false,
    this.saldoInicial = 0,
    this.saldoInicialNota,
    this.puedeAjustarSaldoInicial = false,
  });

  final String id;
  final String nombre;
  final String creadoPor;
  final bool esTesorero;
  final String? codigo;
  final bool esCreador;
  final double saldoInicial;
  final String? saldoInicialNota;
  final bool puedeAjustarSaldoInicial;

  factory SemilleroDetail.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    final Map<String, dynamic> saldo = asMap(map['saldoInicial']);
    return SemilleroDetail(
      id: asString(map['id'] ?? map['_id']),
      nombre: asString(map['nombre']),
      creadoPor: asString(map['creadoPor']),
      esTesorero: asBool(map['esTesorero']),
      codigo: asNullableString(map['codigo']),
      esCreador: asBool(map['esCreador']),
      saldoInicial: asDouble(saldo['monto']),
      saldoInicialNota: asNullableString(saldo['nota']),
      puedeAjustarSaldoInicial: asBool(map['puedeAjustarSaldoInicial']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'nombre': nombre,
    'creadoPor': creadoPor,
    'esTesorero': esTesorero,
    'codigo': codigo,
    'esCreador': esCreador,
    'saldoInicial': <String, dynamic>{
      'monto': saldoInicial,
      'nota': saldoInicialNota,
    },
    'puedeAjustarSaldoInicial': puedeAjustarSaldoInicial,
  };
}
