Self-contained Gradle + Java 21 project (offline ready)

Overview

This repository is a minimal Java project wired so you can run Gradle and Java offline by placing a Java 21 JDK and a Gradle distribution inside the repo. I provide small launcher scripts that will use the bundled JDK and the bundled Gradle distribution.

What I created for you

- build.gradle - minimal Gradle build configured for Java 21 (toolchain).
- settings.gradle - project name.
- gradlew.bat - Windows launcher that uses the bundled JDK and bundled Gradle.
- gradlew - Unix launcher (bash) that does the same.
- src/main/java/com/example/App.java - small sample application.
- gradle.properties - useful JVM options.
- .gitignore - ignores the bundled binaries (optional)
- docker-compose.yml - sample compose file used by the docker-compose Gradle plugin

Docker Compose plugin added

This project now applies the Avast Gradle Docker Compose plugin (plugin id: `com.avast.gradle.docker-compose`). The plugin is configured in `build.gradle` (see the `dockerCompose {}` block). The plugin adds tasks such as `dockerComposeUp`, `dockerComposeDown`, and others.

Important: plugin resolution & offline use

Gradle resolves plugins from the Gradle Plugin Portal (or other configured repositories). For a first-time run you typically need network access so Gradle can download the plugin artifacts. After that, Gradle caches the plugin and uses the local cache for subsequent runs.

Options to get the plugin into your environment:

1) Recommended (if you have network access, one-time):
   - Run Gradle (or use the Docker-based commands below) once while online, so plugin artifacts are downloaded to your Gradle cache.
   - Example (Windows - cmd.exe) using Docker to avoid needing a local Gradle install:

```cmd
cd /d N:\code\gradlew_infra

docker run --rm -v N:/code/gradlew_infra:/home/gradle/project -v "%USERPROFILE%/.gradle":/home/gradle/.gradle -w /home/gradle/project gradle:8.5-jdk21 gradle --no-daemon dockerComposeUp --dry-run
```

   - This command uses the `gradle:8.5-jdk21` image to run Gradle inside Docker and will download the plugin into `%USERPROFILE%/.gradle` on Windows. After this one run you can operate offline as long as the host Gradle cache remains available and you don't change plugin versions.

2) Offline without ever going online (advanced):
   - Create a local Maven repository and place the plugin artifacts there, then update `settings.gradle` pluginManagement to point to that repo. This requires downloading the plugin artifacts from an online machine and copying them into a `local-maven-repo` directory in this repo. See `settings.gradle` for commented examples (mavenLocal and file-based repo).

3) Use a custom Docker image that already bundles the plugin and Gradle (fully offline):
   - Build a Docker image while online that contains Gradle and the plugin, then save/load the image on the offline machine. The plugin will already be present in the image.

How to run the Docker Compose tasks (examples)

- Start services (and wait for health checks):
  - Windows (cmd.exe):

```cmd
cd /d N:\code\gradlew_infra

docker run --rm -v N:/code/gradlew_infra:/home/gradle/project -v "%USERPROFILE%/.gradle":/home/gradle/.gradle -w /home/gradle/project gradle:8.5-jdk21 gradle dockerComposeUp
```

  - Unix / macOS (bash):

```bash
cd /path/to/gradlew_infra

docker run --rm -v "$(pwd)":/home/gradle/project -v "$HOME/.gradle":/home/gradle/.gradle -w /home/gradle/project gradle:8.5-jdk21 gradle dockerComposeUp
```

- Stop and remove services:

```bash
# Unix
docker run --rm -v "$(pwd)":/home/gradle/project -w /home/gradle/project gradle:8.5-jdk21 gradle dockerComposeDown
```

Notes and tips

- The sample `docker-compose.yml` uses `nginx:alpine` and exposes port 8080 -> 80. The plugin `waitForTcpPorts` and `healthcheck` options let Gradle wait for services to be healthy.
- If you prefer not to use Docker for Gradle, make sure you provide a Gradle installation (or wrapper) and a Java 21 JDK as described earlier.
- To avoid Gradle attempting to download toolchain JDKs, `gradle.properties` includes `org.gradle.java.installations.auto-download=false`.

Next steps I can help with

- Add a small `gradle-docker` launcher script that automatically runs Gradle inside Docker when no local Java is present.
- Create a Dockerfile that bundles Gradle + the plugin so you can run fully offline without additional setup.
- Help prepare a local Maven repository with the required plugin artifacts for fully offline plugin resolution.
