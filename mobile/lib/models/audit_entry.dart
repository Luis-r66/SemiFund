import '../core/utils/json_utils.dart';

class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.accion,
    required this.usuario,
    this.entidad,
    this.detalle,
    this.creadoEn,
  });

  final String id;
  final String accion;
  final String usuario;
  final String? entidad;
  final String? detalle;
  final DateTime? creadoEn;

  String get titulo => _titulos[accion] ?? accion;

  static const Map<String, String> _titulos = <String, String>{
    'integrante.crear': 'Integrante creado',
    'integrante.editar': 'Integrante editado',
    'integrante.desactivar': 'Integrante desactivado',
    'aporte.crear': 'Cuota creada',
    'aporte.cuotas_masivas': 'Cuotas del mes creadas',
    'aporte.reportado': 'Pago reportado',
    'aporte.abono_reportado': 'Abono reportado',
    'aporte.abono_registrado': 'Abono registrado',
    'aporte.abono_aprobado': 'Abono aprobado',
    'aporte.abono_rechazado': 'Abono rechazado',
    'aporte.abono_anulado': 'Abono anulado',
    'aporte.pago_total': 'Pago total registrado',
    'aporte.reporte_rechazado': 'Reporte rechazado',
    'gasto.crear': 'Gasto registrado',
  };

  factory AuditEntry.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    final dynamic autor = map['usuarioId'];
    final Map<String, dynamic> usuario = asMap(autor);
    final String nombre = [
      asString(usuario['nombres']),
      asString(usuario['apellidos']),
    ].where((String parte) => parte.isNotEmpty).join(' ');
    return AuditEntry(
      id: asString(map['id'] ?? map['_id']),
      accion: asString(map['accion']),
      entidad: asNullableString(map['entidad']),
      detalle: asNullableString(map['detalle']),
      creadoEn: asDate(map['creadoEn']),
      usuario: nombre.isNotEmpty
          ? nombre
          : asString(
              usuario['nombre'],
              fallback: asString(usuario['email'], fallback: 'Sistema'),
            ),
    );
  }
}
