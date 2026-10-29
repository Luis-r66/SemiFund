import '../core/utils/json_utils.dart';
import 'member.dart';
import 'semillero_membership.dart';
import 'user.dart';

class MembershipAccount {
  const MembershipAccount({
    required this.id,
    required this.esTesorero,
    required this.estado,
    this.usuario,
    this.integrante,
    this.fechaSolicitud,
  });

  final String id;
  final UserModel? usuario;
  final Member? integrante;
  final bool esTesorero;
  final MembershipStatus estado;
  final DateTime? fechaSolicitud;

  factory MembershipAccount.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    final dynamic usuarioJson = map['usuario'];
    final dynamic integranteJson = map['integrante'];
    return MembershipAccount(
      id: asString(map['id'] ?? map['_id']),
      usuario: usuarioJson == null ? null : UserModel.fromJson(usuarioJson),
      integrante: integranteJson == null
          ? null
          : Member.fromJson(integranteJson),
      esTesorero: asBool(map['esTesorero']),
      estado: MembershipStatus.fromApi(map['estado']),
      fechaSolicitud: asDate(map['fechaSolicitud']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'usuario': usuario?.toJson(),
    'integrante': integrante?.toJson(),
    'esTesorero': esTesorero,
    'estado': estado.apiValue,
    'fechaSolicitud': fechaSolicitud?.toIso8601String(),
  };
}
