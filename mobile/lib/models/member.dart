import '../core/utils/formatters.dart';
import '../core/utils/json_utils.dart';
import 'user.dart';

class Member {
  const Member({
    required this.id,
    required this.nombre,
    required this.programa,
    required this.semestre,
    required this.activo,
    this.nombres = '',
    this.apellidos = '',
    this.tipoUsuario,
    this.esCuentaVinculada = false,
    this.fechaIngreso,
  });

  final String id;
  final String nombre;
  final String nombres;
  final String apellidos;
  final String programa;
  final int? semestre;
  final bool activo;
  final UserType? tipoUsuario;
  final bool esCuentaVinculada;
  final DateTime? fechaIngreso;

  bool get esProfesor => tipoUsuario == UserType.profesor;

  String get programLabel => esProfesor ? 'Área' : 'Programa';

  String get semesterLabel =>
      esProfesor || semestre == null ? 'No aplica' : '$semestreº';

  String get initials => initialsFromParts(
    nombres: nombres,
    apellidos: apellidos,
    fullName: nombre,
  );

  factory Member.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    return Member(
      id: asString(map['id'] ?? map['_id']),
      nombre: asString(map['nombre']),
      nombres: asString(map['nombres']),
      apellidos: asString(map['apellidos']),
      programa: asString(map['programa']),
      semestre: map['semestre'] == null ? null : asInt(map['semestre']),
      activo: asBool(map['activo'], fallback: true),
      tipoUsuario: UserType.tryParse(map['tipoUsuario']),
      esCuentaVinculada: asBool(map['esCuentaVinculada']),
      fechaIngreso: asDate(map['fechaIngreso']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'nombre': nombre,
    'nombres': nombres,
    'apellidos': apellidos,
    'programa': programa,
    'semestre': semestre,
    'activo': activo,
    'tipoUsuario': tipoUsuario?.apiValue,
    'esCuentaVinculada': esCuentaVinculada,
    'fechaIngreso': fechaIngreso?.toIso8601String(),
  };

  Member copyWith({
    String? id,
    String? nombre,
    String? nombres,
    String? apellidos,
    String? programa,
    int? semestre,
    bool? activo,
    UserType? tipoUsuario,
    bool? esCuentaVinculada,
    DateTime? fechaIngreso,
  }) {
    return Member(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      programa: programa ?? this.programa,
      semestre: semestre ?? this.semestre,
      activo: activo ?? this.activo,
      tipoUsuario: tipoUsuario ?? this.tipoUsuario,
      esCuentaVinculada: esCuentaVinculada ?? this.esCuentaVinculada,
      fechaIngreso: fechaIngreso ?? this.fechaIngreso,
    );
  }
}
