import '../core/utils/json_utils.dart';

class SemilleroDetail {
  const SemilleroDetail({
    required this.id,
    required this.nombre,
    required this.creadoPor,
    required this.esTesorero,
    this.codigo,
  });

  final String id;
  final String nombre;
  final String creadoPor;
  final bool esTesorero;
  final String? codigo;

  factory SemilleroDetail.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    return SemilleroDetail(
      id: asString(map['id'] ?? map['_id']),
      nombre: asString(map['nombre']),
      creadoPor: asString(map['creadoPor']),
      esTesorero: asBool(map['esTesorero']),
      codigo: asNullableString(map['codigo']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'nombre': nombre,
    'creadoPor': creadoPor,
    'esTesorero': esTesorero,
    'codigo': codigo,
  };
}
