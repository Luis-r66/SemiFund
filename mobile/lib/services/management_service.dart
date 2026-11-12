import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../core/utils/json_utils.dart';
import '../models/contribution.dart';
import '../models/expense.dart';
import '../models/import_result.dart';
import '../models/member.dart';

const String xlsxMimeType =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

class CsvDownload {
  const CsvDownload({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}

class BulkContributionResult {
  const BulkContributionResult({required this.creadas, required this.omitidas});

  final int creadas;
  final int omitidas;

  factory BulkContributionResult.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    return BulkContributionResult(
      creadas: asInt(map['creadas']),
      omitidas: asList(map['omitidas']).length,
    );
  }
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

  Future<Contribution> reportContribution(
    String id, {
    String? referencia,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (referencia != null && referencia.trim().isNotEmpty) {
      body['referencia'] = referencia.trim();
    }
    final dynamic data = await _api.patch(
      '/contributions/$id/report',
      data: body,
    );
    return Contribution.fromJson(data);
  }

  Future<Contribution> rejectContribution(String id, {String? motivo}) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (motivo != null && motivo.trim().isNotEmpty) {
      body['motivo'] = motivo.trim();
    }
    final dynamic data = await _api.patch(
      '/contributions/$id/reject',
      data: body,
    );
    return Contribution.fromJson(data);
  }

  Future<Contribution> addPayment(
    String id, {
    double? monto,
    String? referencia,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (monto != null) body['monto'] = monto;
    if (referencia != null && referencia.trim().isNotEmpty) {
      body['referencia'] = referencia.trim();
    }
    final dynamic data = await _api.post(
      '/contributions/$id/payments',
      data: body,
    );
    return Contribution.fromJson(data);
  }

  Future<Contribution> uploadReceipt(
    String id,
    String abonoId, {
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    final dynamic data = await _api.postMultipart(
      '/contributions/$id/payments/$abonoId/comprobante',
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
    return Contribution.fromJson(data);
  }

  Future<Contribution> approvePayment(String id, String abonoId) async {
    final dynamic data = await _api.patch(
      '/contributions/$id/payments/$abonoId/approve',
    );
    return Contribution.fromJson(data);
  }

  Future<Contribution> rejectPayment(
    String id,
    String abonoId, {
    String? motivo,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (motivo != null && motivo.trim().isNotEmpty) {
      body['motivo'] = motivo.trim();
    }
    final dynamic data = await _api.patch(
      '/contributions/$id/payments/$abonoId/reject',
      data: body,
    );
    return Contribution.fromJson(data);
  }

  Future<Contribution> voidPayment(
    String id,
    String abonoId, {
    String? motivo,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (motivo != null && motivo.trim().isNotEmpty) {
      body['motivo'] = motivo.trim();
    }
    final dynamic data = await _api.patch(
      '/contributions/$id/payments/$abonoId/void',
      data: body,
    );
    return Contribution.fromJson(data);
  }

  Future<BulkContributionResult> createBulkContributions({
    required String mes,
    required double monto,
    required String concepto,
  }) async {
    final dynamic data = await _api.post(
      '/contributions/bulk',
      data: <String, dynamic>{'mes': mes, 'monto': monto, 'concepto': concepto},
    );
    return BulkContributionResult.fromJson(data);
  }

  Future<CsvDownload> exportMovimientos() {
    return _download('/reports/movimientos.csv', 'movimientos.csv');
  }

  Future<CsvDownload> exportLibro() {
    return _download('/reports/libro.xlsx', 'libro.xlsx', accept: xlsxMimeType);
  }

  Future<CsvDownload> downloadTemplate() {
    return _download(
      '/reports/plantilla.xlsx',
      'plantilla.xlsx',
      accept: xlsxMimeType,
    );
  }

  Future<ImportPreview> previewImport(Uint8List bytes) async {
    final dynamic data = await _api.postBytes(
      '/import/preview',
      bytes,
      contentType: xlsxMimeType,
    );
    return ImportPreview.fromJson(data);
  }

  Future<ImportResult> confirmImport(Uint8List bytes) async {
    final dynamic data = await _api.postBytes(
      '/import/confirm',
      bytes,
      contentType: xlsxMimeType,
    );
    return ImportResult.fromJson(data);
  }

  Future<CsvDownload> _download(
    String path,
    String fallbackName, {
    String accept = 'text/csv',
  }) async {
    final Response<List<int>> response = await _api.getBytes(
      path,
      accept: accept,
    );
    final String? disposition = response.headers.value('content-disposition');
    final RegExpMatch? match = disposition == null
        ? null
        : RegExp(r'filename="?([^";]+)"?').firstMatch(disposition);
    return CsvDownload(
      bytes: Uint8List.fromList(response.data ?? const <int>[]),
      filename: match?.group(1) ?? fallbackName,
    );
  }

  Future<Expense> createExpense({
    required String descripcion,
    required String categoria,
    required double monto,
    String? fecha,
  }) async {
    final dynamic data = await _api.post(
      '/expenses',
      data: <String, dynamic>{
        'descripcion': descripcion,
        'categoria': categoria,
        'monto': monto,
        'fecha': ?fecha,
      },
    );
    return Expense.fromJson(data);
  }
}
