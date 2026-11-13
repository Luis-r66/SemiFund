import '../core/utils/json_utils.dart';
import 'balance.dart';

/// Lo que el inicio necesita, en una sola llamada a `/summary`.
class HomeSummary {
  const HomeSummary({
    required this.balance,
    required this.activeMembers,
    required this.pendingContributions,
    required this.expensesCount,
  });

  final Balance balance;
  final int activeMembers;
  final int pendingContributions;
  final int expensesCount;

  factory HomeSummary.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    return HomeSummary(
      balance: Balance.fromJson(map['balance']),
      activeMembers: asInt(map['activeMembers']),
      pendingContributions: asInt(map['pendingContributions']),
      expensesCount: asInt(map['expensesCount']),
    );
  }
}
