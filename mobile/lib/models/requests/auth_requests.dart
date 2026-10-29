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
    required this.nombre,
    required this.email,
    required this.password,
  });

  final String nombre;
  final String email;
  final String password;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'nombre': nombre,
    'email': email,
    'password': password,
  };
}
