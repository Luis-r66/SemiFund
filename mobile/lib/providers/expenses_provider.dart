import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/balance.dart';
import '../models/expense.dart';
import '../services/dashboard_service.dart';
import '../services/management_service.dart';

class ExpensesProvider extends ChangeNotifier {
  ExpensesProvider(this._reads, this._writes);

  final DashboardService _reads;
  final ManagementService _writes;

  List<Expense> _expenses = <Expense>[];
  Balance _balance = Balance.empty;
  bool _loading = false;
  String? _error;
  int _requestId = 0;

  List<Expense> get expenses => List.unmodifiable(_expenses);
  Balance get balance => _balance;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    final int request = ++_requestId;
    _loading = true;
    _error = null;
    _expenses = <Expense>[];
    notifyListeners();
    try {
      final List<dynamic> results = await Future.wait<dynamic>(
        <Future<dynamic>>[_reads.expenses(), _reads.balance()],
      );
      if (request != _requestId) return;
      _expenses = results[0] as List<Expense>;
      _balance = results[1] as Balance;
    } on ApiException catch (error) {
      if (request != _requestId) return;
      _error = error.message;
    } finally {
      if (request == _requestId) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  /// Relanza el 409 del backend (saldo insuficiente) para que la UI lo muestre.
  Future<void> create({
    required String descripcion,
    required String categoria,
    required double monto,
  }) async {
    await _writes.createExpense(
      descripcion: descripcion,
      categoria: categoria,
      monto: monto,
    );
    await load();
  }
}
