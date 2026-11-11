import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  /// Release: API pública en Render (el APK no necesita backend local).
  /// Debug: emulador local con `npm run dev`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kReleaseMode
        ? 'https://semifund-api.onrender.com/api'
        : 'http://10.0.2.2:3000/api',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);
}
