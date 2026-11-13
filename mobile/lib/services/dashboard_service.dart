import '../core/network/api_client.dart';
import '../core/utils/json_utils.dart';
import '../models/audit_entry.dart';
import '../models/app_notification.dart';
import '../models/balance.dart';
import '../models/contribution.dart';
import '../models/expense.dart';
import '../models/home_summary.dart';
import '../models/member.dart';
import '../models/member_statement.dart';
import '../models/paged.dart';

class DashboardService {
  DashboardService(this._api);

  final ApiClient _api;

  Future<Balance> balance() async {
    final dynamic data = await _api.get('/balance');
    return Balance.fromJson(data);
  }

  /// Saldo, integrantes activos, cuotas por cobrar y gastos en una llamada.
  Future<HomeSummary> summary() async {
    final dynamic data = await _api.get('/summary');
    return HomeSummary.fromJson(data);
  }

  Future<MemberStatement> memberStatement(String memberId) async {
    final dynamic data = await _api.get('/members/$memberId/statement');
    return MemberStatement.fromJson(data);
  }

  Future<List<AuditEntry>> auditLog({int limit = 100}) async {
    final dynamic data = await _api.get(
      '/audit',
      queryParameters: <String, dynamic>{'limit': limit},
    );
    return asList(data).map(AuditEntry.fromJson).toList();
  }

  Future<Member> member(String id) async {
    final dynamic data = await _api.get('/members/$id');
    return Member.fromJson(data);
  }

  /// Lista completa (sin paginar). Se usa donde hace falta todo el semillero:
  /// el selector de integrantes de los formularios.
  Future<List<Member>> members({bool? activo}) async {
    final dynamic data = await _api.get(
      '/members',
      queryParameters: activo == null
          ? null
          : <String, dynamic>{'activo': activo.toString()},
    );
    return asList(data).map(Member.fromJson).toList();
  }

  Future<Paged<Member>> membersPage({
    bool? activo,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, dynamic> query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (activo != null) query['activo'] = activo.toString();
    if (search != null && search.trim().isNotEmpty) {
      query['q'] = search.trim();
    }
    final dynamic data = await _api.get('/members', queryParameters: query);
    return Paged<Member>.fromJson(data, Member.fromJson);
  }

  /// Lista completa de aportes. Queda para pantallas que necesitan todos los
  /// registros (por ejemplo el historial de un integrante).
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

  Future<Paged<Contribution>> contributionsPage({
    ContributionStatus? status,
    String? memberId,
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, dynamic> query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) query['status'] = status.queryValue;
    if (memberId != null && memberId.isNotEmpty) query['memberId'] = memberId;

    final dynamic data = await _api.get(
      '/contributions',
      queryParameters: query,
    );
    return Paged<Contribution>.fromJson(data, Contribution.fromJson);
  }

  Future<List<Expense>> expenses() async {
    final dynamic data = await _api.get('/expenses');
    return asList(data).map(Expense.fromJson).toList();
  }

  Future<Paged<Expense>> expensesPage({int page = 1, int limit = 20}) async {
    final dynamic data = await _api.get(
      '/expenses',
      queryParameters: <String, dynamic>{'page': page, 'limit': limit},
    );
    return Paged<Expense>.fromJson(data, Expense.fromJson);
  }

  Future<Paged<AppNotification>> notificationsPage({
    int page = 1,
    int limit = 20,
  }) async {
    final dynamic data = await _api.get(
      '/notifications',
      queryParameters: <String, dynamic>{'page': page, 'limit': limit},
    );
    return Paged<AppNotification>.fromJson(data, AppNotification.fromJson);
  }

  Future<int> notificationsUnread() async {
    final dynamic data = await _api.get('/notifications/unread-count');
    return asInt(asMap(data)['count']);
  }

  Future<int> markNotificationsRead() async {
    final dynamic data = await _api.post('/notifications/read-all');
    return asInt(asMap(data)['updated']);
  }

  Future<AppNotification> markNotificationRead(String id) async {
    final dynamic data = await _api.patch('/notifications/$id/read');
    return AppNotification.fromJson(data);
  }
}
