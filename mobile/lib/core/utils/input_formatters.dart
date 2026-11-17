import 'package:flutter/services.dart';

/// Letras con tildes y ñ, espacios, apóstrofe, punto y guion. Sin números.
final List<TextInputFormatter> lettersOnlyFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r"[\p{L} '.\-]", unicode: true)),
];

/// Nombre del semillero: además admite & y coma, pero tampoco números.
final List<TextInputFormatter> semilleroNameFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r"[\p{L} '.,&\-]", unicode: true)),
];
