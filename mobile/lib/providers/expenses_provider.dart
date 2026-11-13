import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/balance.dart';
import '../models/expense.dart';
import '../models/paged.dart';
import '../services/dashboard_service.dart';
import '../services/management_service.dart';

class ExpensesProvider extends ChangeNotifier {
  ExpensesProvider(this._reads, this._writes, {this.pageSize = 20});

  final DashboardService _reads;
  final ManagementService _writes;
  final int pageSize;

  List<Expense> _expenses = <Expense>[];
  Balance _balance = Balance.empty;
  int _total = 0;
  int _page = 1;
  int _pages = 1;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  int _requestId = 0;

  List<Expense> get expenses => List.unmodifiable(_expenses);
  Balance get balance => _balance;
  int get total => _total;
  int get page => _page;
  int get pages => _pages;
  bool get hasMore => _page < _pages;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;

  Future<void> load() async {
    final int request = ++_requestId;
    _page = 1;
    _loading = true;
    _error = null;
    _expenses = <Expense>[];
    notifyListeners();
    try {
      final List<dynamic> results = await Future.wait<dynamic>(
        <Future<dynamic>>[
          _reads.expensesPage(page: 1, limit: pageSize),
          _reads.balance(),
        ],
      );
      if (request != _requestId) return;
      final Paged<Expense> page = results[0] as Paged<Expense>;
      _expenses = page.items;
      _total = page.total;
      _pages = page.pages;
      _page = page.page;
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

  Future<void> goToPage(int page) async {
    if (page < 1 || page > _pages || page == _page) return;
    final int request = ++_requestId;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final Paged<Expense> result = await _reads.expensesPage(
        page: page,
        limit: pageSize,
      );
      if (request != _requestId) return;
      _expenses = result.items;
      _total = result.total;
      _pages = result.pages;
      _page = result.page;
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

  Future<void> loadMore() async {
    if (_loading || _loadingMore || !hasMore) return;
    final int request = _requestId;
    _loadingMore = true;
    notifyListeners();
    try {
      final Paged<Expense> result = await _reads.expensesPage(
        page: _page + 1,
        limit: pageSize,
      );
      if (request != _requestId) return;
      final Set<String> existentes = _expenses.map((Expense e) => e.id).toSet();
      _expenses = <Expense>[
        ..._expenses,
        ...result.items.where((Expense e) => !existentes.contains(e.id)),
      ];
      _total = result.total;
      _pages = result.pages;
      _page = result.page;
    } on ApiException catch (error) {
      if (request != _requestId) return;
      _error = error.message;
    } finally {
      if (request == _requestId) {
        _loadingMore = false;
        notifyListeners();
      }
    }
  }

  /// Relanza el 409 del backend (saldo insuficiente) para que la UI lo muestre.
  Future<void> create({
    required String descripcion,
    required String categoria,
    required double monto,
    String? fecha,
  }) async {
    await _writes.createExpense(
      descripcion: descripcion,
      categoria: categoria,
      monto: monto,
      fecha: fecha,
    );
    await load();
  }
}
