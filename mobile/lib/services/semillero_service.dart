import '../core/network/api_client.dart';
import '../core/utils/json_utils.dart';
import '../models/join_result.dart';
import '../models/membership_account.dart';
import '../models/requests/semillero_requests.dart';
import '../models/semillero_detail.dart';
import '../models/semillero_membership.dart';

class SemilleroService {
  SemilleroService(this._api);

  final ApiClient _api;

  Future<List<SemilleroMembership>> list() async {
    final dynamic data = await _api.get('/semilleros');
    return asList(data).map(SemilleroMembership.fromJson).toList();
  }

  Future<SemilleroDetail> detail() async {
    final dynamic data = await _api.get('/semilleros/me');
    return SemilleroDetail.fromJson(data);
  }

  Future<SemilleroDetail> create(
    String nombre, {
    double? saldoInicial,
    String? saldoInicialNota,
  }) async {
    final dynamic data = await _api.post(
      '/semilleros',
      data: CreateSemilleroRequest(
        nombre: nombre,
        saldoInicial: saldoInicial,
        saldoInicialNota: saldoInicialNota,
      ).toJson(),
    );
    final Map<String, dynamic> map = asMap(data);
    return SemilleroDetail.fromJson(map['semillero']);
  }

  /// Ajuste auditado del saldo inicial del semillero activo.
  /// Devuelve el saldo disponible resultante (puede quedar negativo).
  Future<double> ajustarSaldoInicial({
    required double monto,
    String? nota,
  }) async {
    final dynamic data = await _api.patch(
      '/semilleros/me/saldo-inicial',
      data: <String, dynamic>{
        'monto': monto,
        if (nota != null && nota.trim().isNotEmpty) 'nota': nota.trim(),
      },
    );
    return asDouble(asMap(data)['saldoDisponible']);
  }

  Future<JoinSemilleroResult> join(String codigo) async {
    final dynamic data = await _api.post(
      '/semilleros/join',
      data: JoinSemilleroRequest(codigo: codigo).toJson(),
    );
    return JoinSemilleroResult.fromJson(data);
  }

  Future<SemilleroDetail> rename(String nombre) async {
    final dynamic data = await _api.patch(
      '/semilleros/me',
      data: <String, dynamic>{'nombre': nombre},
    );
    final Map<String, dynamic> map = asMap(data);
    return SemilleroDetail.fromJson(<String, dynamic>{
      ...map,
      'esTesorero': true,
      'creadoPor': '',
    });
  }

  /// Actualiza nombre, ciudad o centro de costos del semillero activo
  /// (solo tesorero). Los tres datos alimentan los documentos del profesor.
  Future<void> updateDatos({
    String? nombre,
    String? ciudad,
    String? centroCostos,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (nombre != null && nombre.trim().isNotEmpty) body['nombre'] = nombre.trim();
    if (ciudad != null) body['ciudad'] = ciudad.trim();
    if (centroCostos != null) body['centroCostos'] = centroCostos.trim();
    if (body.isEmpty) return;
    await _api.patch('/semilleros/me', data: body);
  }

  Future<String> rotateCode() async {
    final dynamic data = await _api.post('/semilleros/me/code/rotate');
    return asString(asMap(data)['codigo']);
  }

  /// Elimina el semillero activo (borrado lógico). Solo el creador puede hacerlo
  /// y debe repetir el nombre exacto como confirmación.
  Future<void> eliminar(String confirmacion) async {
    await _api.delete(
      '/semilleros/me',
      data: <String, dynamic>{'confirmacion': confirmacion},
    );
  }

  /// Saca al usuario del semillero activo sin borrarlo.
  Future<void> salir() async {
    await _api.post('/semilleros/me/leave');
  }

  Future<List<MembershipAccount>> accounts() async {
    final dynamic data = await _api.get('/semilleros/me/accounts');
    return asList(data).map(MembershipAccount.fromJson).toList();
  }

  Future<void> updateAccount(
    String membershipId, {
    MembershipStatus? estado,
    bool? esTesorero,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (estado != null) body['estado'] = estado.apiValue;
    if (esTesorero != null) body['esTesorero'] = esTesorero;
    await _api.patch('/semilleros/me/accounts/$membershipId', data: body);
  }
}
