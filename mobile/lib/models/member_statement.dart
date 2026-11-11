import '../core/utils/json_utils.dart';
import 'contribution.dart';

class MemberStatement {
  const MemberStatement({
    required this.esperado,
    required this.cobrado,
    required this.saldo,
    required this.vencido,
    required this.alDia,
    required this.cuotas,
  });

  final double esperado;
  final double cobrado;
  final double saldo;
  final double vencido;
  final bool alDia;
  final List<Contribution> cuotas;

  factory MemberStatement.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    final Map<String, dynamic> resumen = asMap(map['resumen']);
    return MemberStatement(
      esperado: asDouble(resumen['esperado']),
      cobrado: asDouble(resumen['cobrado']),
      saldo: asDouble(resumen['saldo']),
      vencido: asDouble(resumen['vencido']),
      alDia: asBool(map['alDia']),
      cuotas: asList(map['cuotas']).map(Contribution.fromJson).toList(),
    );
  }
}
