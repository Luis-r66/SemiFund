import '../core/utils/json_utils.dart';

enum MembershipStatus {
  pendiente('pendiente', 'Pendiente'),
  activo('activo', 'Activo'),
  rechazado('rechazado', 'Rechazado'),
  inactivo('inactivo', 'Inactivo'),
  desconocido('desconocido', 'Desconocido');

  const MembershipStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static MembershipStatus fromApi(dynamic value) {
    final String normalized = asString(value).toLowerCase();
    for (final MembershipStatus status in MembershipStatus.values) {
      if (status.apiValue == normalized) return status;
    }
    return MembershipStatus.desconocido;
  }
}

class SemilleroMembership {
  const SemilleroMembership({
    required this.id,
    required this.semilleroId,
    required this.nombre,
    required this.esTesorero,
    required this.estado,
    required this.miembros,
    this.codigo,
    this.esCreador = false,
    this.saldoInicial = 0,
    this.saldoInicialNota,
    this.puedeAjustarSaldoInicial = false,
    this.ciudad,
    this.centroCostos,
  });

  final String id;
  final String semilleroId;
  final String nombre;
  final bool esTesorero;
  final MembershipStatus estado;
  final int miembros;
  final String? codigo;
  final bool esCreador;

  /// Dinero con el que arrancó el semillero. No es un aporte de nadie.
  final double saldoInicial;
  final String? saldoInicialNota;
  final bool puedeAjustarSaldoInicial;

  /// Ciudad y centro de costos: datos que se imprimen en los documentos.
  final String? ciudad;
  final String? centroCostos;

  bool get isActive => estado == MembershipStatus.activo;

  String get roleLabel {
    if (!isActive) return estado.label;
    return esTesorero ? 'Tesorero' : 'Integrante';
  }

  factory SemilleroMembership.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    final String semilleroId = asString(map['semilleroId'] ?? map['_id']);
    return SemilleroMembership(
      id: asString(map['id'] ?? map['_id'] ?? semilleroId),
      semilleroId: semilleroId,
      nombre: asString(map['semilleroNombre'] ?? map['nombre']),
      esTesorero: asBool(map['esTesorero']),
      estado: MembershipStatus.fromApi(map['estado']),
      miembros: asInt(map['miembros']),
      codigo: asNullableString(map['semilleroCodigo'] ?? map['codigo']),
      esCreador: asBool(map['esCreador']),
      saldoInicial: asDouble(map['saldoInicial']),
      saldoInicialNota: asNullableString(map['saldoInicialNota']),
      puedeAjustarSaldoInicial: asBool(map['puedeAjustarSaldoInicial']),
      ciudad: asNullableString(map['ciudad']),
      centroCostos: asNullableString(map['centroCostos']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'semilleroId': semilleroId,
    'semilleroNombre': nombre,
    'semilleroCodigo': codigo,
    'esTesorero': esTesorero,
    'esCreador': esCreador,
    'estado': estado.apiValue,
    'miembros': miembros,
    'saldoInicial': saldoInicial,
    'saldoInicialNota': saldoInicialNota,
    'puedeAjustarSaldoInicial': puedeAjustarSaldoInicial,
    'ciudad': ciudad,
    'centroCostos': centroCostos,
  };

  SemilleroMembership copyWith({
    String? id,
    String? semilleroId,
    String? nombre,
    bool? esTesorero,
    MembershipStatus? estado,
    int? miembros,
    String? codigo,
    bool? esCreador,
    double? saldoInicial,
    String? saldoInicialNota,
    bool? puedeAjustarSaldoInicial,
    String? ciudad,
    String? centroCostos,
  }) {
    return SemilleroMembership(
      id: id ?? this.id,
      semilleroId: semilleroId ?? this.semilleroId,
      nombre: nombre ?? this.nombre,
      esTesorero: esTesorero ?? this.esTesorero,
      estado: estado ?? this.estado,
      miembros: miembros ?? this.miembros,
      codigo: codigo ?? this.codigo,
      esCreador: esCreador ?? this.esCreador,
      saldoInicial: saldoInicial ?? this.saldoInicial,
      saldoInicialNota: saldoInicialNota ?? this.saldoInicialNota,
      puedeAjustarSaldoInicial:
          puedeAjustarSaldoInicial ?? this.puedeAjustarSaldoInicial,
      ciudad: ciudad ?? this.ciudad,
      centroCostos: centroCostos ?? this.centroCostos,
    );
  }
}
