import '../core/utils/json_utils.dart';
import 'semillero_membership.dart';

class JoinSemilleroResult {
  const JoinSemilleroResult({
    required this.semilleroId,
    required this.semilleroNombre,
    required this.estado,
    this.mensaje,
  });

  final String semilleroId;
  final String semilleroNombre;
  final MembershipStatus estado;
  final String? mensaje;

  factory JoinSemilleroResult.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    return JoinSemilleroResult(
      semilleroId: asString(map['semilleroId']),
      semilleroNombre: asString(map['semilleroNombre']),
      estado: MembershipStatus.fromApi(map['estado']),
      mensaje: asNullableString(map['mensaje']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'semilleroId': semilleroId,
    'semilleroNombre': semilleroNombre,
    'estado': estado.apiValue,
    'mensaje': mensaje,
  };
}
