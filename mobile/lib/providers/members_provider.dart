import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/member.dart';
import '../services/dashboard_service.dart';
import '../services/management_service.dart';

class MembersProvider extends ChangeNotifier {
  MembersProvider(this._reads, this._writes);

  final DashboardService _reads;
  final ManagementService _writes;

  List<Member> _members = <Member>[];
  bool _loading = false;
  String? _error;
  int _requestId = 0;

  List<Member> get members => List.unmodifiable(_members);
  List<Member> get activeMembers =>
      _members.where((Member item) => item.activo).toList();
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    final int request = ++_requestId;
    _loading = true;
    _error = null;
    _members = <Member>[];
    notifyListeners();
    try {
      final List<Member> result = await _reads.members();
      if (request != _requestId) return;
      _members = result;
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

  Future<Member> create({
    required String nombre,
    required String programa,
    required int semestre,
  }) async {
    final Member created = await _writes.createMember(
      nombre: nombre,
      programa: programa,
      semestre: semestre,
    );
    await load();
    return created;
  }

  Future<Member> update(String id, Map<String, dynamic> changes) async {
    final Member updated = await _writes.updateMember(id, changes);
    await load();
    return updated;
  }

  Future<void> deactivate(String id) async {
    await _writes.deactivateMember(id);
    await load();
  }

  Future<void> reactivate(String id) =>
      update(id, <String, dynamic>{'activo': true});
}
