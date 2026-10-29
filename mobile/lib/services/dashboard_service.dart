import '../core/network/api_client.dart';
import '../core/utils/json_utils.dart';
import '../models/balance.dart';
import '../models/contribution.dart';
import '../models/expense.dart';
import '../models/member.dart';

class DashboardService {
  DashboardService(this._api);

  final ApiClient _api;

  Future<Balance> balance() async {
    final dynamic data = await _api.get('/balance');
    return Balance.fromJson(data);
  }

  Future<Member> member(String id) async {
    final dynamic data = await _api.get('/members/$id');
    return Member.fromJson(data);
  }

  Future<List<Member>> members({bool? activo}) async {
    final dynamic data = await _api.get(
      '/members',
      queryParameters: activo == null
          ? null
          : <String, dynamic>{'activo': activo.toString()},
    );
    return asList(data).map(Member.fromJson).toList();
  }

  Future<List<Contribution>> contributions({
    ContributionStatus? status,
    String? memberId,
  }) async {
    final Map<String, dynamic> query = <String, dynamic>{};
    if (status != null) query['status'] = status.queryValue;
    if (memberId != null && memberId.isNotEmpty) query['memberId'] = memberId;

    final dynamic data = await _api.get(
      '/contributions',
      queryParameters: query.isEmpty ? null : query,
    );
    return asList(data).map(Contribution.fromJson).toList();
  }

  Future<List<Expense>> expenses() async {
    final dynamic data = await _api.get('/expenses');
    return asList(data).map(Expense.fromJson).toList();
  }
}
