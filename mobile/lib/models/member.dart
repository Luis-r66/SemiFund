import '../core/utils/json_utils.dart';

class Member {
  const Member({
    required this.id,
    required this.nombre,
    required this.programa,
    required this.semestre,
    required this.activo,
    this.fechaIngreso,
  });

  final String id;
  final String nombre;
  final String programa;
  final int semestre;
  final bool activo;
  final DateTime? fechaIngreso;

  factory Member.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    return Member(
      id: asString(map['id'] ?? map['_id']),
      nombre: asString(map['nombre']),
      programa: asString(map['programa']),
      semestre: asInt(map['semestre']),
      activo: asBool(map['activo'], fallback: true),
      fechaIngreso: asDate(map['fechaIngreso']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'nombre': nombre,
    'programa': programa,
    'semestre': semestre,
    'activo': activo,
    'fechaIngreso': fechaIngreso?.toIso8601String(),
  };

  Member copyWith({
    String? id,
    String? nombre,
    String? programa,
    int? semestre,
    bool? activo,
    DateTime? fechaIngreso,
  }) {
    return Member(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      programa: programa ?? this.programa,
      semestre: semestre ?? this.semestre,
      activo: activo ?? this.activo,
      fechaIngreso: fechaIngreso ?? this.fechaIngreso,
    );
  }
}
