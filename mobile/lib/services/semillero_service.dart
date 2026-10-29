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

  Future<SemilleroDetail> create(String nombre) async {
    final dynamic data = await _api.post(
      '/semilleros',
      data: CreateSemilleroRequest(nombre: nombre).toJson(),
    );
    final Map<String, dynamic> map = asMap(data);
    return SemilleroDetail.fromJson(map['semillero']);
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

  Future<String> rotateCode() async {
    final dynamic data = await _api.post('/semilleros/me/code/rotate');
    return asString(asMap(data)['codigo']);
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
