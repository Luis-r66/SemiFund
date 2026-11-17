import '../core/utils/json_utils.dart';
import 'abono.dart';

enum ContributionStatus {
  pendiente('pendiente', 'pending', 'Pendiente'),
  pagado('pagado', 'paid', 'Pagado'),
  vencido('vencido', 'overdue', 'Vencido'),
  reportado('reportado', 'reported', 'Reportado');

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

/// Cuota: mensualidad única por integrante y mes.
/// Aporte: contribución para un destino concreto (viaje, materiales, etc.).
enum ContributionType {
  cuota('cuota', 'Cuota'),
  aporte('aporte', 'Aporte');

  const ContributionType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ContributionType fromApi(dynamic value) {
    return asString(value).toLowerCase() == 'aporte'
        ? ContributionType.aporte
        : ContributionType.cuota;
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
    this.tipo = ContributionType.cuota,
    this.fechaPago,
    this.createdAt,
    this.esPropio = false,
    this.referencia,
    this.fechaReporte,
    this.motivoRechazo,
    this.montoPagado,
    this.abonos = const <Abono>[],
    this.integranteNombre,
  });

  final String id;
  final String integranteId;
  final double monto;
  final String mes;
  final String concepto;
  final ContributionStatus estado;
  final ContributionType tipo;
  final DateTime? fechaPago;
  final DateTime? createdAt;
  final bool esPropio;
  final String? referencia;
  final DateTime? fechaReporte;
  final String? motivoRechazo;
  final double? montoPagado;
  final List<Abono> abonos;

  /// Nombre del integrante que llega con el listado paginado.
  final String? integranteNombre;

  bool get isPaid => estado == ContributionStatus.pagado;

  /// Dinero ya cobrado. Si el backend no lo envía (datos antiguos), un pagado cuenta completo.
  double get cobrado => montoPagado ?? (isPaid ? monto : 0);

  double get saldoPendiente =>
      (monto - cobrado).clamp(0, double.infinity).toDouble();

  bool get isParcial => cobrado > 0 && saldoPendiente > 0;

  bool get hasAbonoReportado =>
      abonos.any((Abono abono) => abono.estado == AbonoStatus.reportado);

  bool get canReport =>
      esPropio &&
      !hasAbonoReportado &&
      saldoPendiente > 0 &&
      (estado == ContributionStatus.pendiente ||
          estado == ContributionStatus.vencido);

  factory Contribution.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    return Contribution(
      id: asString(map['id'] ?? map['_id']),
      integranteId: asString(map['integranteId']),
      monto: asDouble(map['monto']),
      mes: asString(map['mes']),
      concepto: asString(map['concepto']),
      estado: ContributionStatus.fromApi(map['estado']),
      tipo: ContributionType.fromApi(map['tipo']),
      fechaPago: asDate(map['fechaPago']),
      createdAt: asDate(map['createdAt']),
      esPropio: asBool(map['esPropio']),
      referencia: asNullableString(map['referencia']),
      fechaReporte: asDate(map['fechaReporte']),
      motivoRechazo: asNullableString(map['motivoRechazo']),
      montoPagado: map['montoPagado'] == null
          ? null
          : asDouble(map['montoPagado']),
      abonos: asList(map['abonos']).map(Abono.fromJson).toList(),
      integranteNombre: asNullableString(map['integranteNombre']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'integranteId': integranteId,
    'monto': monto,
    'mes': mes,
    'concepto': concepto,
    'estado': estado.apiValue,
    'tipo': tipo.apiValue,
    'fechaPago': fechaPago?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
    'esPropio': esPropio,
    'referencia': referencia,
    'fechaReporte': fechaReporte?.toIso8601String(),
    'motivoRechazo': motivoRechazo,
  };

  Contribution copyWith({
    String? id,
    String? integranteId,
    double? monto,
    String? mes,
    String? concepto,
    ContributionStatus? estado,
    ContributionType? tipo,
    DateTime? fechaPago,
    DateTime? createdAt,
    bool? esPropio,
    String? referencia,
    DateTime? fechaReporte,
    String? motivoRechazo,
    double? montoPagado,
    List<Abono>? abonos,
  }) {
    return Contribution(
      id: id ?? this.id,
      integranteId: integranteId ?? this.integranteId,
      monto: monto ?? this.monto,
      mes: mes ?? this.mes,
      concepto: concepto ?? this.concepto,
      estado: estado ?? this.estado,
      tipo: tipo ?? this.tipo,
      fechaPago: fechaPago ?? this.fechaPago,
      createdAt: createdAt ?? this.createdAt,
      esPropio: esPropio ?? this.esPropio,
      referencia: referencia ?? this.referencia,
      fechaReporte: fechaReporte ?? this.fechaReporte,
      motivoRechazo: motivoRechazo ?? this.motivoRechazo,
      montoPagado: montoPagado ?? this.montoPagado,
      abonos: abonos ?? this.abonos,
    );
  }
}
