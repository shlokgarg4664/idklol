import org.gradle.api.initialization.resolve.RepositoriesMode
import java.io.File
import java.util.Properties

pluginManagement {
    val localPropertiesFile = File(settings.rootDir, "local.properties")
    var flutterSdkPath: String? = null

    if (localPropertiesFile.exists()) {
        // THE FIX: Using the full, secret magic name so it can't be ignored.
        val properties = java.util.Properties()
        localPropertiesFile.inputStream().use { properties.load(it) }
        flutterSdkPath = properties.getProperty("flutter.sdk")
    }

    if (flutterSdkPath != null) {
        includeBuild(File(flutterSdkPath, "packages/flutter_tools/gradle"))
    }

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "sports_app"
include(":app")

