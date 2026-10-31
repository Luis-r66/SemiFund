import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/contribution.dart';
import '../models/member.dart';
import '../services/dashboard_service.dart';
import '../services/management_service.dart';

class ContributionsProvider extends ChangeNotifier {
  ContributionsProvider(this._reads, this._writes);

  final DashboardService _reads;
  final ManagementService _writes;

  List<Contribution> _items = <Contribution>[];
  List<Member> _members = <Member>[];
  ContributionStatus? _filter;
  bool _loading = false;
  String? _error;
  int _requestId = 0;

  List<Contribution> get items => List.unmodifiable(_items);
  List<Member> get members => List.unmodifiable(_members);
  ContributionStatus? get filter => _filter;
  bool get loading => _loading;
  String? get error => _error;

  String memberName(String integranteId) {
    for (final Member member in _members) {
      if (member.id == integranteId) return member.nombre;
    }
    return 'Integrante no disponible';
  }

  Future<void> load({ContributionStatus? status}) async {
    final int request = ++_requestId;
    _filter = status;
    _loading = true;
    _error = null;
    _items = <Contribution>[];
    notifyListeners();
    try {
      final List<dynamic> results = await Future.wait<dynamic>(
        <Future<dynamic>>[
          _reads.contributions(status: status),
          _reads.members(),
        ],
      );
      if (request != _requestId) return;
      _items = results[0] as List<Contribution>;
      _members = results[1] as List<Member>;
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

  Future<void> refresh() => load(status: _filter);

  Future<void> create({
    required String integranteId,
    required double monto,
    required String mes,
    required String concepto,
  }) async {
    await _writes.createContribution(
      integranteId: integranteId,
      monto: monto,
      mes: mes,
      concepto: concepto,
    );
    await refresh();
  }

  Future<void> pay(Contribution contribution) async {
    await _writes.payContribution(contribution.id);
    await refresh();
  }

  Future<void> report(Contribution contribution, {String? referencia}) async {
    await _writes.reportContribution(contribution.id, referencia: referencia);
    await refresh();
  }

  Future<void> reject(Contribution contribution, {String? motivo}) async {
    await _writes.rejectContribution(contribution.id, motivo: motivo);
    await refresh();
  }

  Future<CsvDownload> exportCsv() => _writes.exportMovimientos();
}
