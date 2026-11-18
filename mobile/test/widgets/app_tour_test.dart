import 'package:flutter_test/flutter_test.dart';
import 'package:semi_fund/widgets/app_tour.dart';
import 'package:semi_fund/widgets/guided_intro.dart';

void main() {
  Set<String> rutas(List<GuidedStep> pasos) =>
      pasos.map((GuidedStep paso) => paso.route).whereType<String>().toSet();

  test('el recorrido del tesorero profesor pasa por toda la app', () {
    final List<GuidedStep> pasos = AppTour.pasosPara(
      tesorero: true,
      profesor: true,
    );

    expect(
      rutas(pasos),
      containsAll(<String>[
        '/home',
        '/contributions',
        '/expenses',
        '/members',
        '/documents',
        '/accounts',
        '/invite',
        '/activity',
        '/profile',
        '/semilleros',
        '/semilleros/settings',
      ]),
    );
    expect(pasos.first.route, '/home');
    expect(pasos.last.title, 'Listo');
  });

  test('el integrante solo recorre las pantallas que puede usar', () {
    final List<GuidedStep> pasos = AppTour.pasosPara(
      tesorero: false,
      profesor: false,
    );
    final Set<String> destino = rutas(pasos);

    expect(
      destino,
      containsAll(<String>[
        '/home',
        '/contributions',
        '/expenses',
        '/members',
        '/profile',
        '/semilleros',
      ]),
    );
    expect(destino, isNot(contains('/accounts')));
    expect(destino, isNot(contains('/invite')));
    expect(destino, isNot(contains('/activity')));
    expect(destino, isNot(contains('/documents')));
    expect(destino, isNot(contains('/semilleros/settings')));
  });

  test(
    'el profesor que no es tesorero ve documentos pero no administración',
    () {
      final Set<String> destino = rutas(
        AppTour.pasosPara(tesorero: false, profesor: true),
      );

      expect(destino, contains('/documents'));
      expect(destino, isNot(contains('/accounts')));
    },
  );

  test('cada paso tiene título y explicación', () {
    for (final bool tesorero in <bool>[true, false]) {
      for (final bool profesor in <bool>[true, false]) {
        for (final GuidedStep paso in AppTour.pasosPara(
          tesorero: tesorero,
          profesor: profesor,
        )) {
          expect(paso.title.trim(), isNotEmpty);
          expect(paso.body.trim(), isNotEmpty);
        }
      }
    }
  });
}
