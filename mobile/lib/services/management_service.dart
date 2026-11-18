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

class FileDownload {
  const FileDownload({required this.bytes, required this.filename});

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

/// Operaciones de escritura del módulo de tesorería. Casi todas requieren rol
/// tesorero en el backend; la creación de un aporte propio es la excepción.
class ManagementService {
  ManagementService(this._api);

  final ApiClient _api;

  Future<Member> createMember({
    required String nombres,
    required String apellidos,
    required String programa,
    required int semestre,
    String? identificacion,
  }) async {
    final dynamic data = await _api.post(
      '/members',
      data: <String, dynamic>{
        'nombres': nombres,
        'apellidos': apellidos,
        'programa': programa,
        'semestre': semestre,
        'identificacion': ?identificacion,
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
    ContributionType tipo = ContributionType.cuota,
  }) async {
    final dynamic data = await _api.post(
      '/contributions',
      data: <String, dynamic>{
        'integranteId': integranteId,
        'monto': monto,
        'mes': mes,
        'concepto': concepto,
        'tipo': tipo.apiValue,
      },
    );
    return Contribution.fromJson(data);
  }

  Future<Contribution> payContribution(String id) async {
    final dynamic data = await _api.patch('/contributions/$id/pay');
    return Contribution.fromJson(data);
  }

  Future<void> deleteContribution(String id) async {
    await _api.delete('/contributions/$id');
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

  /// Registra un abono. El integrante envía siempre el comprobante en el mismo
  /// multipart; el tesorero puede registrar el dinero sin archivo.
  Future<Contribution> addPayment(
    String id, {
    double? monto,
    String? referencia,
    Uint8List? comprobanteBytes,
    String? comprobanteNombre,
    String? comprobanteTipo,
  }) async {
    final Map<String, dynamic> fields = <String, dynamic>{};
    if (monto != null) fields['monto'] = monto;
    if (referencia != null && referencia.trim().isNotEmpty) {
      fields['referencia'] = referencia.trim();
    }

    final dynamic data;
    if (comprobanteBytes != null) {
      data = await _api.postMultipart(
        '/contributions/$id/payments',
        bytes: comprobanteBytes,
        filename: comprobanteNombre ?? 'comprobante',
        contentType: comprobanteTipo ?? 'application/octet-stream',
        fields: fields,
      );
    } else {
      data = await _api.post('/contributions/$id/payments', data: fields);
    }
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
    List<String> integranteIds = const <String>[],
    ContributionType tipo = ContributionType.cuota,
  }) async {
    final dynamic data = await _api.post(
      '/contributions/bulk',
      data: <String, dynamic>{
        'mes': mes,
        'monto': monto,
        'concepto': concepto,
        'tipo': tipo.apiValue,
        if (integranteIds.isNotEmpty) 'integranteIds': integranteIds,
      },
    );
    return BulkContributionResult.fromJson(data);
  }

  Future<FileDownload> exportLibro() {
    return _download('/reports/libro.xlsx', 'libro.xlsx', accept: xlsxMimeType);
  }

  Future<FileDownload> downloadTemplate() {
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

  Future<FileDownload> _download(
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
    return FileDownload(
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
