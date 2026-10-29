import '../core/utils/json_utils.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.nombre,
    required this.email,
  });

  final String id;
  final String nombre;
  final String email;

  factory UserModel.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    return UserModel(
      id: asString(map['id'] ?? map['_id']),
      nombre: asString(map['nombre']),
      email: asString(map['email']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'nombre': nombre,
    'email': email,
  };

  UserModel copyWith({String? id, String? nombre, String? email}) {
    return UserModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
    );
  }
}
