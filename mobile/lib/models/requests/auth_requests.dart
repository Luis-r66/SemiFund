import '../user.dart';

class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'email': email,
    'password': password,
  };
}

class RegisterRequest {
  const RegisterRequest({
    required this.nombres,
    required this.apellidos,
    required this.email,
    required this.password,
  });

  final String nombres;
  final String apellidos;
  final String email;
  final String password;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'nombres': nombres,
    'apellidos': apellidos,
    'email': email,
    'password': password,
  };
}

class UpdateProfileRequest {
  const UpdateProfileRequest({
    required this.nombres,
    required this.apellidos,
    required this.tipoUsuario,
    required this.programa,
    this.semestre,
  });

  final String nombres;
  final String apellidos;
  final UserType tipoUsuario;
  final String programa;
  final int? semestre;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'nombres': nombres,
    'apellidos': apellidos,
    'tipoUsuario': tipoUsuario.apiValue,
    'programa': programa,
    'semestre': semestre,
  };
}

class ForgotPasswordRequest {
  const ForgotPasswordRequest({required this.email});

  final String email;

  Map<String, dynamic> toJson() => <String, dynamic>{'email': email};
}

class ResetPasswordRequest {
  const ResetPasswordRequest({
    required this.email,
    required this.code,
    required this.password,
  });

  final String email;
  final String code;
  final String password;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'email': email,
    'code': code,
    'password': password,
  };
}

class ChangePasswordRequest {
  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'currentPassword': currentPassword,
    'newPassword': newPassword,
  };
}
