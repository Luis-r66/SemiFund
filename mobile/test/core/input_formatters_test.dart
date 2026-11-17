import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:semi_fund/core/utils/input_formatters.dart';

TextEditingValue _apply(TextInputFormatter formatter, String texto) {
  return formatter.formatEditUpdate(
    TextEditingValue.empty,
    TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    ),
  );
}

void main() {
  test('el nombre del semillero descarta números y conserva signos', () {
    final TextInputFormatter formatter = semilleroNameFormatters.first;
    expect(_apply(formatter, 'Semillero 2026').text, 'Semillero ');
    expect(
      _apply(formatter, 'Investigación & Gestión, Grupo A').text,
      'Investigación & Gestión, Grupo A',
    );
    expect(_apply(formatter, 'Diseño-Web').text, 'Diseño-Web');
  });

  test('los nombres de personas descartan números', () {
    final TextInputFormatter formatter = lettersOnlyFormatters.first;
    expect(_apply(formatter, 'Ana2 Torres').text, 'Ana Torres');
    expect(_apply(formatter, 'Peñaloza').text, 'Peñaloza');
  });
}
