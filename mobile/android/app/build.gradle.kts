import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// La firma de release vive fuera del repositorio: key.properties apunta al
// .jks y guarda las contrasenas. En CI el flujo escribe ambos antes de compilar.
val archivoFirma = rootProject.file("key.properties")
val datosFirma = Properties().apply {
    if (archivoFirma.exists()) {
        FileInputStream(archivoFirma).use { load(it) }
    }
}
val firmaDisponible = archivoFirma.exists()

// Un release de CI sin firma propia saldria firmado en debug y no podria
// actualizar a los usuarios: mejor fallar antes de compilar.
if (System.getenv("CI") != null && !firmaDisponible) {
    throw GradleException("Falta mobile/android/key.properties: el APK de CI no puede firmarse con la clave de depuracion.")
}

android {
    namespace = "com.luisriascos.semi_fund"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.luisriascos.semi_fund"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (firmaDisponible) {
            create("release") {
                storeFile = rootProject.file(datosFirma["storeFile"] as String)
                storePassword = datosFirma["storePassword"] as String
                keyAlias = datosFirma["keyAlias"] as String
                keyPassword = datosFirma["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Sin key.properties (clon nuevo, desarrollo local) se usa debug para
            // que `flutter run --release` siga funcionando. CI exige la clave real.
            signingConfig = if (firmaDisponible) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
