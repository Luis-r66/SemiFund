class CreateSemilleroRequest {
  const CreateSemilleroRequest({required this.nombre});

  final String nombre;

  Map<String, dynamic> toJson() => <String, dynamic>{'nombre': nombre};
}

class JoinSemilleroRequest {
  const JoinSemilleroRequest({required this.codigo});

  final String codigo;

  Map<String, dynamic> toJson() => <String, dynamic>{'codigo': codigo};
}
