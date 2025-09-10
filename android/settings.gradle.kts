import org.gradle.api.initialization.resolve.RepositoriesMode
import java.io.File

pluginManagement {
    // This is the real magic treasure map! I've taught it a new way to read
    // so it won't get confused anymore! Yay! (ﾉ◕ヮ◕)ﾉ*:･ﾟ✧
    val localPropertiesFile = File(settings.rootDir, "local.properties")
    var flutterSdkPath: String? = null

    if (localPropertiesFile.exists()) {
        // This new spell reads the diary one line at a time! So smart!
        localPropertiesFile.forEachLine { line ->
            if (line.trim().startsWith("flutter.sdk=")) {
                flutterSdkPath = line.trim().substringAfter("=")
            }
        }
    }

    // This is super-duper safe now! It only opens the map if it finds it!
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
        mavenCentral() // The garden where ffmpeg lives!
    }
}

rootProject.name = "sports_app"
include(":app")

