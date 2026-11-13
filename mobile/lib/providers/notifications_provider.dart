import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/app_notification.dart';
import '../models/paged.dart';
import '../services/dashboard_service.dart';

/// Avisos del semillero activo: primera página, contador sin leer y
/// "marcar todas como leídas".
class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider(this._reads, {this.pageSize = 20});

  final DashboardService _reads;
  final int pageSize;

  List<AppNotification> _items = <AppNotification>[];
  String? _semilleroId;
  int _unread = 0;
  int _total = 0;
  int _page = 1;
  int _pages = 1;
  bool _loading = false;
  bool _loadingMore = false;
  bool _marked = false;
  String? _error;
  int _requestId = 0;

  List<AppNotification> get items => List.unmodifiable(_items);
  int get unread => _unread;
  int get total => _total;
  int get page => _page;
  int get pages => _pages;
  bool get hasMore => _page < _pages;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;

  /// Carga la primera página y el contador. Si cambia el semillero, reinicia.
  Future<void> load(String semilleroId) async {
    final bool mismoSemillero = _semilleroId == semilleroId;
    if (!mismoSemillero) {
      _items = <AppNotification>[];
      _unread = 0;
      _total = 0;
      _page = 1;
      _pages = 1;
    }
    _semilleroId = semilleroId;
    final int request = ++_requestId;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final List<dynamic> results = await Future.wait<dynamic>(
        <Future<dynamic>>[
          _reads.notificationsPage(page: 1, limit: pageSize),
          _reads.notificationsUnread(),
        ],
      );
      if (request != _requestId) return;
      final Paged<AppNotification> page = results[0] as Paged<AppNotification>;
      _items = page.items;
      _total = page.total;
      _pages = page.pages;
      _page = page.page;
      _unread = results[1] as int;
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

  /// Solo el contador, para refrescar la campanita sin recargar la lista.
  Future<void> refreshUnread() async {
    if (_semilleroId == null) return;
    try {
      final int count = await _reads.notificationsUnread();
      if (count == _unread) return;
      _unread = count;
      notifyListeners();
    } on ApiException {
      // Un fallo del contador no debe mostrar error en pantalla.
    }
  }

  Future<void> loadMore() async {
    if (_loading || _loadingMore || !hasMore || _semilleroId == null) return;
    final int request = _requestId;
    _loadingMore = true;
    notifyListeners();
    try {
      final Paged<AppNotification> result = await _reads.notificationsPage(
        page: _page + 1,
        limit: pageSize,
      );
      if (request != _requestId) return;
      final Set<String> existentes = _items
          .map((AppNotification item) => item.id)
          .toSet();
      _items = <AppNotification>[
        ..._items,
        ...result.items.where(
          (AppNotification item) => !existentes.contains(item.id),
        ),
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

  Future<void> markAllRead() async {
    if (_unread == 0 || _marked) return;
    _marked = true;
    final int pendientes = _unread;
    _unread = 0;
    _items = _items
        .map((AppNotification item) => item.copyWith(leida: true))
        .toList();
    notifyListeners();
    try {
      await _reads.markNotificationsRead();
    } on ApiException {
      // Si falla, se restaura el contador para reintentar.
      _unread = pendientes;
      notifyListeners();
    } finally {
      _marked = false;
    }
  }

  Future<void> markRead(AppNotification item) async {
    if (item.leida) return;
    _items = _items
        .map(
          (AppNotification actual) =>
              actual.id == item.id ? actual.copyWith(leida: true) : actual,
        )
        .toList();
    if (_unread > 0) _unread--;
    notifyListeners();
    try {
      await _reads.markNotificationRead(item.id);
    } on ApiException {
      _items = _items
          .map(
            (AppNotification actual) =>
                actual.id == item.id ? actual.copyWith(leida: false) : actual,
          )
          .toList();
      _unread++;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _requestId++;
    super.dispose();
  }
}
