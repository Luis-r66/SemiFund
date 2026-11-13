import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/balance.dart';
import '../models/home_summary.dart';
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
      final HomeSummary summary = await _service.summary();

      if (request != _requestId) return;

      _snapshot = HomeSnapshot(
        balance: summary.balance,
        activeMembers: summary.activeMembers,
        pendingContributions: summary.pendingContributions,
        expensesCount: summary.expensesCount,
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
