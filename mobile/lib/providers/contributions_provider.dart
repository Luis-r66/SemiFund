import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/abono.dart';
import '../models/contribution.dart';
import '../models/import_result.dart';
import '../models/paged.dart';
import '../services/dashboard_service.dart';
import '../services/management_service.dart';

class ContributionsProvider extends ChangeNotifier {
  ContributionsProvider(this._reads, this._writes, {this.pageSize = 20});

  final DashboardService _reads;
  final ManagementService _writes;
  final int pageSize;

  List<Contribution> _items = <Contribution>[];
  ContributionStatus? _filter;
  int _total = 0;
  int _page = 1;
  int _pages = 1;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  int _requestId = 0;

  List<Contribution> get items => List.unmodifiable(_items);
  ContributionStatus? get filter => _filter;
  int get total => _total;
  int get page => _page;
  int get pages => _pages;
  bool get hasMore => _page < _pages;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;

  String nameOf(Contribution item) =>
      item.integranteNombre ?? 'Integrante no disponible';

  Future<void> load({ContributionStatus? status}) async {
    final int request = ++_requestId;
    _filter = status;
    _page = 1;
    _loading = true;
    _error = null;
    _items = <Contribution>[];
    notifyListeners();
    try {
      final Paged<Contribution> result = await _reads.contributionsPage(
        status: status,
        page: 1,
        limit: pageSize,
      );
      if (request != _requestId) return;
      _items = result.items;
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
      final Paged<Contribution> result = await _reads.contributionsPage(
        status: _filter,
        page: page,
        limit: pageSize,
      );
      if (request != _requestId) return;
      _items = result.items;
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
      final Paged<Contribution> result = await _reads.contributionsPage(
        status: _filter,
        page: _page + 1,
        limit: pageSize,
      );
      if (request != _requestId) return;
      final Set<String> existentes = _items
          .map((Contribution item) => item.id)
          .toSet();
      _items = <Contribution>[
        ..._items,
        ...result.items.where(
          (Contribution item) => !existentes.contains(item.id),
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

  Future<void> refresh() => _reload(_page);

  /// Vuelve a la primera página manteniendo el filtro activo.
  Future<void> reloadFirstPage() => _reload(1);

  Future<void> _reload(int page) async {
    final int request = ++_requestId;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      Paged<Contribution> result = await _reads.contributionsPage(
        status: _filter,
        page: page.clamp(1, _pages < 1 ? 1 : _pages),
        limit: pageSize,
      );
      if (request != _requestId) return;
      // Si la última página quedó vacía (se pagó o rechazó el único registro),
      // se muestra la última página que sí tiene datos.
      if (result.items.isEmpty &&
          result.total > 0 &&
          result.page > result.pages) {
        result = await _reads.contributionsPage(
          status: _filter,
          page: result.pages,
          limit: pageSize,
        );
        if (request != _requestId) return;
      }
      _items = result.items;
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
    await reloadFirstPage();
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

  Future<void> addPayment(
    Contribution contribution, {
    double? monto,
    String? referencia,
  }) async {
    await _writes.addPayment(
      contribution.id,
      monto: monto,
      referencia: referencia,
    );
    await refresh();
  }

  Future<void> uploadReceipt(
    Contribution contribution,
    Abono abono, {
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    await _writes.uploadReceipt(
      contribution.id,
      abono.id,
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
    await refresh();
  }

  Future<void> approvePayment(Contribution contribution, Abono abono) async {
    await _writes.approvePayment(contribution.id, abono.id);
    await refresh();
  }

  Future<void> rejectPayment(
    Contribution contribution,
    Abono abono, {
    String? motivo,
  }) async {
    await _writes.rejectPayment(contribution.id, abono.id, motivo: motivo);
    await refresh();
  }

  Future<void> voidPayment(
    Contribution contribution,
    Abono abono, {
    String? motivo,
  }) async {
    await _writes.voidPayment(contribution.id, abono.id, motivo: motivo);
    await refresh();
  }

  Future<BulkContributionResult> createBulk({
    required String mes,
    required double monto,
    required String concepto,
  }) async {
    final BulkContributionResult result = await _writes.createBulkContributions(
      mes: mes,
      monto: monto,
      concepto: concepto,
    );
    await reloadFirstPage();
    return result;
  }

  Future<CsvDownload> exportCsv() => _writes.exportMovimientos();

  Future<CsvDownload> exportExcel() => _writes.exportLibro();

  Future<CsvDownload> downloadTemplate() => _writes.downloadTemplate();

  Future<ImportPreview> previewImport(Uint8List bytes) =>
      _writes.previewImport(bytes);

  Future<ImportResult> confirmImport(Uint8List bytes) =>
      _writes.confirmImport(bytes);
}
