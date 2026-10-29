import '../core/network/api_client.dart';
import '../models/contribution.dart';
import '../models/expense.dart';
import '../models/member.dart';

/// Operaciones de escritura del mÃ³dulo de tesorerÃ­a. Todas requieren rol tesorero
/// en el backend; la UI solo las expone a tesoreros.
class ManagementService {
  ManagementService(this._api);

  final ApiClient _api;

  Future<Member> createMember({
    required String nombres,
    required String apellidos,
    required String programa,
    required int semestre,
  }) async {
    final dynamic data = await _api.post(
      '/members',
      data: <String, dynamic>{
        'nombres': nombres,
        'apellidos': apellidos,
        'programa': programa,
        'semestre': semestre,
      },
    );
    return Member.fromJson(data);
  }

  /// EnvÃ­a solo los campos a cambiar. El backend aplica allowlist.
  Future<Member> updateMember(String id, Map<String, dynamic> changes) async {
    final dynamic data = await _api.put('/members/$id', data: changes);
    return Member.fromJson(data);
  }

  Future<void> deactivateMember(String id) async {
    await _api.delete('/members/$id');
  }

  Future<Contribution> createContribution({
    required String integranteId,
    required double monto,
    required String mes,
    required String concepto,
  }) async {
    final dynamic data = await _api.post(
      '/contributions',
      data: <String, dynamic>{
        'integranteId': integranteId,
        'monto': monto,
        'mes': mes,
        'concepto': concepto,
      },
    );
    return Contribution.fromJson(data);
  }

  Future<Contribution> payContribution(String id) async {
    final dynamic data = await _api.patch('/contributions/$id/pay');
    return Contribution.fromJson(data);
  }

  Future<Expense> createExpense({
    required String descripcion,
    required String categoria,
    required double monto,
  }) async {
    final dynamic data = await _api.post(
      '/expenses',
      data: <String, dynamic>{
        'descripcion': descripcion,
        'categoria': categoria,
        'monto': monto,
      },
    );
    return Expense.fromJson(data);
  }
}
