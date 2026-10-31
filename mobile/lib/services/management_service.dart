import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/contribution.dart';
import '../models/expense.dart';
import '../models/member.dart';

class CsvDownload {
  const CsvDownload({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}

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

  Future<Contribution> reportContribution(String id, {String? referencia}) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (referencia != null && referencia.trim().isNotEmpty) {
      body['referencia'] = referencia.trim();
    }
    final dynamic data = await _api.patch('/contributions/$id/report', data: body);
    return Contribution.fromJson(data);
  }

  Future<Contribution> rejectContribution(String id, {String? motivo}) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (motivo != null && motivo.trim().isNotEmpty) {
      body['motivo'] = motivo.trim();
    }
    final dynamic data = await _api.patch('/contributions/$id/reject', data: body);
    return Contribution.fromJson(data);
  }

  Future<CsvDownload> exportMovimientos() async {
    final Response<List<int>> response = await _api.getBytes('/reports/movimientos.csv');
    final String? disposition = response.headers.value('content-disposition');
    final RegExpMatch? match = disposition == null
        ? null
        : RegExp(r'filename="?([^";]+)"?').firstMatch(disposition);
    return CsvDownload(
      bytes: Uint8List.fromList(response.data ?? const <int>[]),
      filename: match?.group(1) ?? 'movimientos.csv',
    );
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
