class CreateSemilleroRequest {
  const CreateSemilleroRequest({
    required this.nombre,
    this.saldoInicial,
    this.saldoInicialNota,
  });

  final String nombre;
  final double? saldoInicial;
  final String? saldoInicialNota;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'nombre': nombre,
    if (saldoInicial != null) 'saldoInicial': saldoInicial,
    if (saldoInicialNota != null && saldoInicialNota!.trim().isNotEmpty)
      'saldoInicialNota': saldoInicialNota!.trim(),
  };
}

class JoinSemilleroRequest {
  const JoinSemilleroRequest({required this.codigo});

  final String codigo;

  Map<String, dynamic> toJson() => <String, dynamic>{'codigo': codigo};
}
