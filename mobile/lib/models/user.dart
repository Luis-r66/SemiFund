import '../core/utils/formatters.dart';
import '../core/utils/json_utils.dart';

enum UserType {
  estudiante('estudiante', 'Estudiante'),
  profesor('profesor', 'Profesor');

  const UserType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static UserType? tryParse(dynamic value) {
    final String normalized = asString(value).toLowerCase();
    for (final UserType type in UserType.values) {
      if (type.apiValue == normalized) return type;
    }
    return null;
  }
}

class UserModel {
  const UserModel({
    required this.id,
    required this.nombre,
    required this.email,
    this.nombres = '',
    this.apellidos = '',
    this.tipoUsuario,
    this.programa,
    this.semestre,
  });

  final String id;
  final String nombre;
  final String nombres;
  final String apellidos;
  final String email;
  final UserType? tipoUsuario;
  final String? programa;
  final int? semestre;

  String get initials => initialsFromParts(
    nombres: nombres,
    apellidos: apellidos,
    fullName: nombre,
  );

  bool get isProfileComplete {
    if (tipoUsuario == null) return false;
    if ((programa ?? '').trim().isEmpty) return false;
    if (tipoUsuario == UserType.estudiante && semestre == null) return false;
    return true;
  }

  factory UserModel.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    return UserModel(
      id: asString(map['id'] ?? map['_id']),
      nombre: asString(map['nombre']),
      nombres: asString(map['nombres']),
      apellidos: asString(map['apellidos']),
      email: asString(map['email']),
      tipoUsuario: UserType.tryParse(map['tipoUsuario']),
      programa: asNullableString(map['programa']),
      semestre: map['semestre'] == null ? null : asInt(map['semestre']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'nombre': nombre,
    'nombres': nombres,
    'apellidos': apellidos,
    'email': email,
    'tipoUsuario': tipoUsuario?.apiValue,
    'programa': programa,
    'semestre': semestre,
  };

  UserModel copyWith({
    String? id,
    String? nombre,
    String? nombres,
    String? apellidos,
    String? email,
    UserType? tipoUsuario,
    String? programa,
    int? semestre,
  }) {
    return UserModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      email: email ?? this.email,
      tipoUsuario: tipoUsuario ?? this.tipoUsuario,
      programa: programa ?? this.programa,
      semestre: semestre ?? this.semestre,
    );
  }
}
