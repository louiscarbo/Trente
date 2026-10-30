pluginManagement {
    repositories {
        mavenCentral()
        gradlePluginPortal()
        google()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        mavenCentral()
        google()
        gradlePluginPortal()
    }
}

rootProject.name = "Trente"

include(":core")

// `gradle -PcoreOnly :core:test` builds and tests the pure-Kotlin logic without the Android SDK.
if (!providers.gradleProperty("coreOnly").isPresent) {
    include(":app")
}
