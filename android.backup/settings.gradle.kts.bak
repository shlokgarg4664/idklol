pluginManagement {
    val properties = java.util.Properties()
    file("local.properties").inputStream().use { properties.load(it) }
    val flutterSdkPath: String = properties.getProperty("flutter.sdk")
        ?: error("flutter.sdk not set in local.properties")
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
    plugins {
        id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false
        id("com.android.application") version "8.1.0" apply false
        id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

include(":app")
