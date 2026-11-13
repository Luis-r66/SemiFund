import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/member.dart';
import '../models/paged.dart';
import '../services/dashboard_service.dart';
import '../services/management_service.dart';

class MembersProvider extends ChangeNotifier {
  MembersProvider(this._reads, this._writes, {this.pageSize = 20});

  final DashboardService _reads;
  final ManagementService _writes;
  final int pageSize;

  List<Member> _members = <Member>[];
  List<Member> _picker = <Member>[];
  String _query = '';
  int _total = 0;
  int _page = 1;
  int _pages = 1;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  int _requestId = 0;

  List<Member> get members => List.unmodifiable(_members);
  List<Member> get activeMembers =>
      _members.where((Member item) => item.activo).toList();

  /// Lista completa para los selectores de los formularios.
  List<Member> get pickerMembers => List.unmodifiable(_picker);

  String get query => _query;
  int get total => _total;
  int get page => _page;
  int get pages => _pages;
  bool get hasMore => _page < _pages;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;

  Future<void> load({String? query}) async {
    final String texto = (query ?? _query).trim();
    final int request = ++_requestId;
    _query = texto;
    _page = 1;
    _loading = true;
    _error = null;
    _members = <Member>[];
    notifyListeners();
    try {
      final Paged<Member> result = await _reads.membersPage(
        search: texto,
        page: 1,
        limit: pageSize,
      );
      if (request != _requestId) return;
      _members = result.items;
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

  Future<void> goToPage(int page) async {
    if (page < 1 || page > _pages || page == _page) return;
    final int request = ++_requestId;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final Paged<Member> result = await _reads.membersPage(
        search: _query,
        page: page,
        limit: pageSize,
      );
      if (request != _requestId) return;
      _members = result.items;
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
      final Paged<Member> result = await _reads.membersPage(
        search: _query,
        page: _page + 1,
        limit: pageSize,
      );
      if (request != _requestId) return;
      final Set<String> existentes = _members.map((Member m) => m.id).toSet();
      _members = <Member>[
        ..._members,
        ...result.items.where((Member m) => !existentes.contains(m.id)),
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

  /// Carga todos los integrantes (sin paginar) para los formularios.
  Future<void> loadForPicker() async {
    try {
      final List<Member> result = await _reads.members(activo: true);
      _picker = result;
      notifyListeners();
    } on ApiException catch (error) {
      _error = error.message;
      notifyListeners();
    }
  }

  Future<Member> create({
    required String nombres,
    required String apellidos,
    required String programa,
    required int semestre,
  }) async {
    final Member created = await _writes.createMember(
      nombres: nombres,
      apellidos: apellidos,
      programa: programa,
      semestre: semestre,
    );
    await load(query: _query);
    return created;
  }

  Future<Member> update(String id, Map<String, dynamic> changes) async {
    final Member updated = await _writes.updateMember(id, changes);
    await load(query: _query);
    return updated;
  }

  Future<void> deactivate(String id) async {
    await _writes.deactivateMember(id);
    await load(query: _query);
  }

  Future<void> reactivate(String id) =>
      update(id, <String, dynamic>{'activo': true});
}
