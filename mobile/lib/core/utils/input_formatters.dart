import 'package:flutter/services.dart';

/// Letras con tildes y ñ, espacios, apóstrofe, punto y guion. Sin números.
final List<TextInputFormatter> lettersOnlyFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r"[\p{L} '.\-]", unicode: true)),
];
