import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:semi_fund/core/network/api_exception.dart';
import 'package:semi_fund/models/app_notification.dart';
import 'package:semi_fund/models/paged.dart';
import 'package:semi_fund/providers/notifications_provider.dart';
import 'package:semi_fund/services/dashboard_service.dart';

class MockDashboardService extends Mock implements DashboardService {}

AppNotification aviso(String id, {bool leida = false}) {
  return AppNotification.fromJson(<String, dynamic>{
    'id': id,
    'tipo': 'cuota_nueva',
    'titulo': 'Nueva cuota',
    'mensaje': 'Se registró la cuota de 2026-11.',
    'leida': leida,
    'createdAt': '2026-11-12T10:00:00.000Z',
  });
}

void main() {
  late MockDashboardService reads;
  late NotificationsProvider provider;

  setUp(() {
    reads = MockDashboardService();
    provider = NotificationsProvider(reads);
  });

  void stubPrimeraPagina({int unread = 1}) {
    when(() => reads.notificationsPage(page: 1, limit: 20)).thenAnswer(
      (_) async => Paged<AppNotification>(
        items: <AppNotification>[aviso('n1')],
        total: 2,
        page: 1,
        limit: 20,
        pages: 2,
      ),
    );
    when(() => reads.notificationsUnread()).thenAnswer((_) async => unread);
  }

  test('carga la primera página y el contador sin leer', () async {
    stubPrimeraPagina(unread: 1);
    await provider.load('s1');

    expect(provider.items.map((AppNotification n) => n.id), <String>['n1']);
    expect(provider.unread, 1);
    expect(provider.total, 2);
    expect(provider.hasMore, isTrue);
  });

  test('marcar leídas limpia el contador y actualiza los avisos', () async {
    stubPrimeraPagina(unread: 1);
    when(() => reads.markNotificationsRead()).thenAnswer((_) async => 1);

    await provider.load('s1');
    await provider.markAllRead();

    expect(provider.unread, 0);
    expect(provider.items.every((AppNotification n) => n.leida), isTrue);
    verify(() => reads.markNotificationsRead()).called(1);
  });

  test('marcar una notificación descuenta solo esa', () async {
    stubPrimeraPagina(unread: 2);
    when(() => reads.markNotificationRead('n1'))
        .thenAnswer((_) async => aviso('n1', leida: true));

    await provider.load('s1');
    await provider.markRead(provider.items.first);

    expect(provider.unread, 1);
    expect(provider.items.first.leida, isTrue);
    verify(() => reads.markNotificationRead('n1')).called(1);
  });

  test('refrescar el contador no recarga la lista', () async {
    stubPrimeraPagina(unread: 0);
    await provider.load('s1');
    when(() => reads.notificationsUnread()).thenAnswer((_) async => 4);

    await provider.refreshUnread();

    expect(provider.unread, 4);
    verify(() => reads.notificationsPage(page: 1, limit: 20)).called(1);
  });

  test('si marcar leídas falla, restaura el contador', () async {
    stubPrimeraPagina(unread: 1);
    when(() => reads.markNotificationsRead()).thenThrow(
      const ApiException(
        message: 'Sin conexión',
        kind: ApiErrorKind.network,
        statusCode: 500,
      ),
    );

    await provider.load('s1');
    await provider.markAllRead();

    expect(provider.unread, 1);
  });
}
