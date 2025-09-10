// This spellbook is now super simple and uses the newest magic!
plugins {
    id("com.android.application") version "8.2.2" apply false
    id("org.jetbrains.kotlin.android") version "1.9.23" apply false
    id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}

