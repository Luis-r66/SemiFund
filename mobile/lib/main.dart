import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/storage/session_storage.dart';
import 'providers/accounts_provider.dart';
import 'providers/contributions_provider.dart';
import 'providers/expenses_provider.dart';
import 'providers/home_provider.dart';
import 'providers/invitation_provider.dart';
import 'providers/members_provider.dart';
import 'providers/session_provider.dart';
import 'services/auth_service.dart';
import 'services/dashboard_service.dart';
import 'services/google_auth_service.dart';
import 'services/management_service.dart';
import 'services/semillero_service.dart';

Future<void> main() async {
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  } else {
    // Carga el script de Google antes del primer clic para no perder el gesto
    // del usuario (el navegador bloquearía la ventana de cuentas).
    unawaited(GoogleAuthService.preparar());
  }

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final SessionStorage storage = SessionStorage(preferences: preferences);
  final ApiClient apiClient = ApiClient(store: storage);

  final AuthService authService = AuthService(apiClient);
  final SemilleroService semilleroService = SemilleroService(apiClient);
  final DashboardService dashboardService = DashboardService(apiClient);
  final ManagementService managementService = ManagementService(apiClient);

  final SessionProvider session = SessionProvider(
    authService: authService,
    semilleroService: semilleroService,
    store: storage,
  );
  apiClient.onUnauthorized = session.expireSession;

  runApp(
    // La clave por usuario recrea los providers al cambiar de cuenta, así los datos
    // de una sesión no quedan visibles en otra en el mismo dispositivo.
    ListenableBuilder(
      listenable: session,
      builder: (BuildContext context, Widget? child) => MultiProvider(
        key: ValueKey<String?>(session.user?.id),
        providers: [
          Provider<DashboardService>.value(value: dashboardService),
          Provider<ManagementService>.value(value: managementService),
          ChangeNotifierProvider<SessionProvider>.value(value: session),
          ChangeNotifierProvider<HomeProvider>(
            create: (_) => HomeProvider(dashboardService),
          ),
          ChangeNotifierProvider<AccountsProvider>(
            create: (_) => AccountsProvider(semilleroService),
          ),
          ChangeNotifierProvider<InvitationProvider>(
            create: (_) => InvitationProvider(semilleroService),
          ),
          ChangeNotifierProvider<MembersProvider>(
            create: (_) => MembersProvider(dashboardService, managementService),
          ),
          ChangeNotifierProvider<ContributionsProvider>(
            create: (_) =>
                ContributionsProvider(dashboardService, managementService),
          ),
          ChangeNotifierProvider<ExpensesProvider>(
            create: (_) =>
                ExpensesProvider(dashboardService, managementService),
          ),
        ],
        child: child,
      ),
      child: SemiFundApp(session: session),
    ),
  );

  unawaited(
    session.bootstrap().whenComplete(() {
      if (!kIsWeb) {
        widgetsBinding.addPostFrameCallback((_) {
          FlutterNativeSplash.remove();
        });
      }
    }),
  );
}
