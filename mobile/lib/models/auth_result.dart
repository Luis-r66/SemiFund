import '../core/utils/json_utils.dart';
import 'user.dart';

class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final UserModel user;

  factory AuthResult.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    return AuthResult(
      token: asString(map['token']),
      user: UserModel.fromJson(map['user']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'token': token,
    'user': user.toJson(),
  };
}
