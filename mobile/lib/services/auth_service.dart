import '../core/network/api_client.dart';
import '../models/auth_result.dart';
import '../models/requests/auth_requests.dart';
import '../models/user.dart';

class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  Future<AuthResult> login(LoginRequest request) async {
    final dynamic data = await _api.post('/auth/login', data: request.toJson());
    return AuthResult.fromJson(data);
  }

  Future<AuthResult> register(RegisterRequest request) async {
    final dynamic data = await _api.post(
      '/auth/register',
      data: request.toJson(),
    );
    return AuthResult.fromJson(data);
  }

  Future<UserModel> me() async {
    final dynamic data = await _api.get('/auth/me');
    return UserModel.fromJson(data);
  }

  Future<void> logout() async {
    await _api.post('/auth/logout');
  }
}
