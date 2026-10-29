import '../core/network/api_client.dart';
import '../core/utils/json_utils.dart';
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

  Future<UserModel> updateProfile(UpdateProfileRequest request) async {
    final dynamic data = await _api.patch('/auth/me', data: request.toJson());
    return UserModel.fromJson(data);
  }

  Future<void> forgotPassword(String email) async {
    await _api.post(
      '/auth/forgot-password',
      data: ForgotPasswordRequest(email: email).toJson(),
    );
  }

  Future<void> resetPassword(ResetPasswordRequest request) async {
    await _api.post('/auth/reset-password', data: request.toJson());
  }

  Future<String> changePassword(ChangePasswordRequest request) async {
    final dynamic data = await _api.patch(
      '/auth/password',
      data: request.toJson(),
    );
    return asString(asMap(data)['token']);
  }

  Future<UserModel> me() async {
    final dynamic data = await _api.get('/auth/me');
    return UserModel.fromJson(data);
  }

  Future<void> logout() async {
    await _api.post('/auth/logout');
  }
}
