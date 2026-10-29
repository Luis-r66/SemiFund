import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../services/semillero_service.dart';

class InvitationProvider extends ChangeNotifier {
  InvitationProvider(this._service);

  final SemilleroService _service;

  String? _code;
  String? _semilleroName;
  bool _loading = false;
  bool _rotating = false;
  String? _error;

  String? get code => _code;
  String? get semilleroName => _semilleroName;
  bool get loading => _loading;
  bool get rotating => _rotating;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    _code = null;
    notifyListeners();
    try {
      final detail = await _service.detail();
      _code = detail.codigo;
      _semilleroName = detail.nombre;
    } on ApiException catch (error) {
      _error = error.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> rotate() async {
    _rotating = true;
    _error = null;
    notifyListeners();
    try {
      _code = await _service.rotateCode();
    } on ApiException catch (error) {
      _error = error.message;
    } finally {
      _rotating = false;
      notifyListeners();
    }
  }
}
