import org.gradle.api.initialization.resolve.RepositoriesMode
import java.io.File
import java.util.Properties // <-- THE FIX: This is the magic spell we were missing!

pluginManagement {
    // This is the magic treasure map! It reads your local.properties file
    // to find where you installed Flutter, and then tells Gradle to look
    // inside that folder for the secret Flutter plugin! Yay! (ﾉ◕ヮ◕)ﾉ*:･ﾟ✧
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
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral() // The garden where ffmpeg lives!
    }
}

rootProject.name = "sports_app"
include(":app")
