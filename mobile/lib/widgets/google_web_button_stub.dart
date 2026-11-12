import 'package:flutter/material.dart';

/// Implementación para plataformas que no son web. No se usa directamente.
Widget buildGoogleWebButton({
  required ValueChanged<String> onIdToken,
  required void Function(String message) onError,
}) {
  return const SizedBox.shrink();
}
