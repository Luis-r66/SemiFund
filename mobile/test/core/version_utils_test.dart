import 'package:flutter_test/flutter_test.dart';
import 'package:semi_fund/core/utils/version_utils.dart';

void main() {
  test('normaliza prefijos, build y preestreno', () {
    expect(normalizarVersion('v1.4.0+8'), '1.4.0');
    expect(normalizarVersion(' 1.4.0 '), '1.4.0');
    expect(normalizarVersion('1.4.0-beta.1'), '1.4.0');
  });

  test('compara versiones por partes numéricas', () {
    expect(compararVersiones('1.4.0', '1.3.0'), greaterThan(0));
    expect(compararVersiones('1.3.0', '1.4.0'), lessThan(0));
    expect(compararVersiones('1.4.0', '1.4'), 0);
    expect(compararVersiones('v1.10.0', '1.9.9'), greaterThan(0));
    expect(compararVersiones('1.3.0+7', '1.3.0'), 0);
  });
}
