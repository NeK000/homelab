// Plugin management must appear before other statements
pluginManagement {
    repositories {
        // Gradle plugin portal is the default for the Avast plugin. If you are online, keep this enabled.
        gradlePluginPortal()

        // For offline use prefer mavenLocal() and/or a local file-based repo with the plugin artifacts.
        // mavenLocal()
        // maven { url = uri("file://${projectDir}/local-maven-repo") }
    }
}

rootProject.name = "gradlew-infra-sample"

// Include the child project 'network'
include("network")

