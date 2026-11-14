import 'package:flutter_test/flutter_test.dart';
import 'package:semi_fund/models/app_release.dart';
import 'package:semi_fund/providers/app_info_provider.dart';

import '../helpers/fakes.dart';

void main() {
  const AppRelease release = AppRelease(
    version: '1.4.0',
    name: 'SemiFund v1.4.0',
    notes: 'Novedades',
    downloadUrl: 'https://example.com/SemiFund.apk',
    pageUrl: 'https://example.com',
    sizeBytes: 60 * 1024 * 1024,
    publishedAt: null,
  );

  test('iniciar lee la versión instalada', () async {
    final FakeAppUpdateGateway gateway = FakeAppUpdateGateway(
      version: '1.4.0',
      build: '8',
    )..due = false;
    final AppInfoProvider info = AppInfoProvider(gateway);

    await info.iniciar();

    expect(info.version, '1.4.0');
    expect(info.versionLabel, 'Versión 1.4.0 (8)');
    expect(info.hasUpdate, isFalse);
  });

  test('iniciar muestra la release cuando hay una nueva', () async {
    final FakeAppUpdateGateway gateway = FakeAppUpdateGateway(version: '1.3.0')
      ..due = true
      ..release = release;
    final AppInfoProvider info = AppInfoProvider(gateway);

    await info.iniciar();

    expect(info.hasUpdate, isTrue);
    expect(info.showBanner, isTrue);
    expect(info.release?.version, '1.4.0');
  });

  test('buscarAhora informa cuando ya está al día', () async {
    final FakeAppUpdateGateway gateway = FakeAppUpdateGateway(version: '1.4.0')
      ..due = true;
    final AppInfoProvider info = AppInfoProvider(gateway);

    final bool found = await info.buscarAhora();

    expect(found, isFalse);
    expect(info.hasUpdate, isFalse);
    expect(info.error, isNull);
  });

  test('descartar oculta el aviso sin borrar la release', () async {
    final FakeAppUpdateGateway gateway = FakeAppUpdateGateway(version: '1.3.0')
      ..due = true
      ..release = release;
    final AppInfoProvider info = AppInfoProvider(gateway);
    await info.iniciar();

    info.descartar();

    expect(info.showBanner, isFalse);
    expect(info.hasUpdate, isTrue);
  });

  test('descargar delega en el servicio', () async {
    final FakeAppUpdateGateway gateway = FakeAppUpdateGateway(version: '1.3.0')
      ..due = true
      ..release = release;
    final AppInfoProvider info = AppInfoProvider(gateway);
    await info.iniciar();

    await info.descargar();

    expect(gateway.abrirLlamado, isTrue);
  });
}
