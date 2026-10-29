import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/balance.dart';
import '../models/contribution.dart';
import '../models/expense.dart';
import '../models/member.dart';
import '../services/dashboard_service.dart';

class HomeSnapshot {
  const HomeSnapshot({
    required this.balance,
    required this.activeMembers,
    required this.pendingContributions,
    required this.expensesCount,
    required this.updatedAt,
  });

  final Balance balance;
  final int activeMembers;
  final int pendingContributions;
  final int expensesCount;
  final DateTime updatedAt;
}

class HomeProvider extends ChangeNotifier {
  HomeProvider(this._service, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DashboardService _service;
  final DateTime Function() _now;

  HomeSnapshot? _snapshot;
  bool _loading = false;
  String? _error;
  String? _semilleroId;
  int _requestId = 0;

  HomeSnapshot? get snapshot => _snapshot;
  bool get loading => _loading;
  String? get error => _error;
  String? get semilleroId => _semilleroId;

  Future<void> load(String semilleroId, {bool force = false}) async {
    if (!force && _semilleroId == semilleroId && _snapshot != null) {
      return;
    }

    if (_semilleroId != semilleroId) {
      _snapshot = null;
    }
    _semilleroId = semilleroId;
    final int request = ++_requestId;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final List<dynamic> results = await Future.wait<dynamic>(
        <Future<dynamic>>[
          _service.balance(),
          _service.members(activo: true),
          _service.contributions(status: ContributionStatus.pendiente),
          _service.expenses(),
        ],
      );

      if (request != _requestId) return;

      final Balance balance = results[0] as Balance;
      final List<Member> members = results[1] as List<Member>;
      final List<Contribution> contributions = results[2] as List<Contribution>;
      final List<Expense> expenses = results[3] as List<Expense>;

      _snapshot = HomeSnapshot(
        balance: balance,
        activeMembers: members.where((Member member) => member.activo).length,
        pendingContributions: contributions
            .where(
              (Contribution item) =>
                  item.estado == ContributionStatus.pendiente,
            )
            .length,
        expensesCount: expenses.length,
        updatedAt: _now(),
      );
      _error = null;
    } on ApiException catch (error) {
      if (request != _requestId) return;
      _error = error.message;
    } catch (_) {
      if (request != _requestId) return;
      _error = 'No se pudo cargar la información del semillero.';
    } finally {
      if (request == _requestId) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refresh() async {
    final String? id = _semilleroId;
    if (id == null) return;
    await load(id, force: true);
  }

  @override
  void dispose() {
    _requestId++;
    super.dispose();
  }
}
