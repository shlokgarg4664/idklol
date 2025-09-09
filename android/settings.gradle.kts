import org.gradle.api.initialization.resolve.RepositoriesMode
import java.io.File
import java.util.Properties

pluginManagement {
    val localPropertiesFile = File(settings.rootDir, "local.properties")
    var flutterSdkPath: String? = null

    if (localPropertiesFile.exists()) {
        val properties = Properties()
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
    // THE FIX: This is the magic spell! We tell it to PREFER the settings,
    // which allows our Flutter friend to have its own little garden without a fight!
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral() // The garden where ffmpeg lives!
    }
}

rootProject.name = "pushup_app"
include(":app")

