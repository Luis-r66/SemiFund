import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'providers/session_provider.dart';
import 'router/app_router.dart';

class SemiFundApp extends StatefulWidget {
  const SemiFundApp({super.key, required this.session});

  final SessionProvider session;

  @override
  State<SemiFundApp> createState() => _SemiFundAppState();
}

class _SemiFundAppState extends State<SemiFundApp> {
  late final AppRouter _appRouter = AppRouter(session: widget.session);

  @override
  void dispose() {
    _appRouter.router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SemiFund',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('es', 'CO'),
      supportedLocales: const <Locale>[
        Locale('es', 'CO'),
        Locale('es'),
        Locale('en'),
      ],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _appRouter.router,
      builder: (BuildContext context, Widget? child) {
        final Widget app = child ?? const SizedBox.shrink();
        final Widget content = kIsWeb
            ? ColoredBox(
                color: AppColors.previewBackground,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: SizedBox.expand(child: app),
                  ),
                ),
              )
            : app;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: AppColors.paper,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: content,
        );
      },
    );
  }
}
