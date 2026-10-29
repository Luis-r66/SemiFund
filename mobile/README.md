# SemiFund Mobile

Aplicación Flutter para la gestión de tesorería de semilleros. Comparte el mismo código para Android, iOS y navegador.

## Requisitos

- Flutter 3.47.8 o superior
- Android SDK para compilar el APK
- macOS con Xcode para compilar iOS

## Backend

La API está desplegada en:

`https://semifund-api.onrender.com/api`

Render Free se duerme por inactividad: la primera petición puede tardar unos segundos.

## Ejecutar

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=https://semifund-api.onrender.com/api
```

## Compilar Android

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://semifund-api.onrender.com/api
```

Salida:

`build/app/outputs/flutter-apk/app-release.apk`

La configuración actual firma el release con la keystore debug. Es suficiente para instalar y probar; para Play Store se necesita una keystore propia.

## Compilar web

```powershell
flutter build web --release --base-href /SemiFund/ --dart-define=API_BASE_URL=https://semifund-api.onrender.com/api
```

Salida: `build/web`

La versión publicada en GitHub Pages queda en:

`https://luis-r66.github.io/SemiFund/`

## iOS

El proyecto iOS ya está configurado (`ios/`, bundle `com.luisriascos.semiFund`, iOS 15+), pero el IPA debe compilarse en macOS con Xcode y firmarse con una cuenta Apple. No es posible generar un IPA instalable desde Windows.

## Calidad

```powershell
flutter analyze
flutter test
```
