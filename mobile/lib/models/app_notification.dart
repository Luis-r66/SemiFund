import '../core/utils/json_utils.dart';

/// Aviso dentro de la app. Se guarda por usuario y semillero.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.leida,
    this.createdAt,
    this.contributionId,
    this.memberId,
  });

  final String id;
  final String tipo;
  final String titulo;
  final String mensaje;
  final bool leida;
  final DateTime? createdAt;
  final String? contributionId;
  final String? memberId;

  factory AppNotification.fromJson(dynamic json) {
    final Map<String, dynamic> map = asMap(json);
    return AppNotification(
      id: asString(map['id']),
      tipo: asString(map['tipo']),
      titulo: asString(map['titulo']),
      mensaje: asString(map['mensaje']),
      leida: map['leida'] == true,
      createdAt: DateTime.tryParse(asString(map['createdAt']))?.toLocal(),
      contributionId: asNullableString(map['contributionId']),
      memberId: asNullableString(map['memberId']),
    );
  }

  AppNotification copyWith({bool? leida}) {
    return AppNotification(
      id: id,
      tipo: tipo,
      titulo: titulo,
      mensaje: mensaje,
      leida: leida ?? this.leida,
      createdAt: createdAt,
      contributionId: contributionId,
      memberId: memberId,
    );
  }
}
