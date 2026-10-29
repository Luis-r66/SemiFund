import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/membership_account.dart';
import '../models/semillero_membership.dart';
import '../services/semillero_service.dart';

class AccountsProvider extends ChangeNotifier {
  AccountsProvider(this._service);

  final SemilleroService _service;

  List<MembershipAccount> _accounts = <MembershipAccount>[];
  bool _loading = false;
  String? _error;
  final Set<String> _busyIds = <String>{};
  int _requestId = 0;

  List<MembershipAccount> get accounts => List.unmodifiable(_accounts);
  bool get loading => _loading;
  String? get error => _error;

  List<MembershipAccount> get pending => _accounts
      .where(
        (MembershipAccount item) => item.estado == MembershipStatus.pendiente,
      )
      .toList();

  List<MembershipAccount> get members => _accounts
      .where((MembershipAccount item) => item.estado == MembershipStatus.activo)
      .toList();

  int get activeTreasurers =>
      members.where((MembershipAccount item) => item.esTesorero).length;

  bool isBusy(String id) => _busyIds.contains(id);

  Future<void> load() async {
    final int request = ++_requestId;
    _loading = true;
    _error = null;
    _accounts = <MembershipAccount>[];
    notifyListeners();
    try {
      final List<MembershipAccount> result = await _service.accounts();
      if (request != _requestId) return;
      _accounts = result;
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

  Future<void> approve(MembershipAccount account) => _run(
    account,
    () => _service.updateAccount(account.id, estado: MembershipStatus.activo),
  );

  Future<void> reject(MembershipAccount account) => _run(
    account,
    () =>
        _service.updateAccount(account.id, estado: MembershipStatus.rechazado),
  );

  Future<void> setTreasurer(MembershipAccount account, {required bool value}) =>
      _run(
        account,
        () => _service.updateAccount(account.id, esTesorero: value),
      );

  Future<void> _run(
    MembershipAccount account,
    Future<void> Function() action,
  ) async {
    _busyIds.add(account.id);
    _error = null;
    notifyListeners();
    try {
      await action();
      await load();
    } on ApiException catch (error) {
      _error = error.message;
      notifyListeners();
      rethrow;
    } finally {
      _busyIds.remove(account.id);
      notifyListeners();
    }
  }
}
