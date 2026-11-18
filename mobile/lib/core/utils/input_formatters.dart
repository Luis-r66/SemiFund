import 'package:flutter/services.dart';

/// Letras con tildes y ñ, espacios, apóstrofe, punto y guion. Sin números.
final List<TextInputFormatter> lettersOnlyFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r"[\p{L} '.\-]", unicode: true)),
];

/// Nombre del semillero: además admite & y coma, pero tampoco números.
final List<TextInputFormatter> semilleroNameFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r"[\p{L} '.,&\-]", unicode: true)),
];

/// Carrera, ciudad y centro de costos: letras y signos habituales, sin dígitos.
final List<TextInputFormatter> simpleTextFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r"[\p{L} '.,&\-()/]", unicode: true)),
];

/// Semestre: solo dígitos.
final List<TextInputFormatter> digitsOnlyFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.digitsOnly,
];

/// Documento de identidad: dígitos con puntos o guiones.
final List<TextInputFormatter> identificationFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r'[0-9.\- ]')),
];
