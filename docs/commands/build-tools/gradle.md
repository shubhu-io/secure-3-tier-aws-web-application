# Gradle

Reference commands for Gradle build system. Not part of this project's runtime (which uses npm) but essential for Android, Kotlin, and general DevOps.

## Installation

```bash
# macOS
brew install gradle

# SDKMAN (recommended)
sdk install gradle

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y gradle

# Windows: Download from gradle.org or use SDKMAN

# Verify installation
gradle --version
```

## Version Check

```bash
gradle --version
```

## Dependency/Package Management

Gradle uses `build.gradle` (or `build.gradle.kts`) for project configuration:

```bash
# Sync project dependencies (downloads defined dependencies)
./gradlew syncDependencies

# Or with Gradle wrapper
./gradlew dependencies

# List all dependencies
./gradlew dependencies

# Download a specific dependency
./gradlew fetchDependencies

# This project doesn't use Gradle directly
```

## Build

```bash
# Basic build (compile and process resources)
./gradlew build

# Clean build (recommended before releases)
./gradlew clean build

# Skip tests during build
./gradlew clean build -x test

# Build without the Gradle wrapper (if gradle is installed globally)
gradle build

# This project doesn't use Gradle directly
```

## Run

Gradle itself doesn't "run" application code directly, but:

```bash
# Run a custom task (if defined in build.gradle)
./gradlew run

# Or run via Java directly after compilation
# (depends on application setup)

# This project doesn't use Gradle runtime
```

## Test

```bash
# Run all tests
./gradlew test

# Run specific test class
./gradlew test --tests "com.example.MyTest*

# Run specific test method
./gradlew test --tests "com.example.MyTest.methodName"

# Skip tests
./gradlew clean build -x test

# This project doesn't use Gradle testing
```

## Lint / Code Quality

```bash
# Check code quality
./gradlew check          # Runs all quality checks (findbugs, pmd, etc.)

# Findbugs
./gradlew findbugsCheck

# PMD
./gradley pmdCheck

# This project doesn't use Gradle linting
```

## Format

```bash
# Google Java Format via Gradle
./gradlew format

# Or configure in build.gradle with plugins

# This project uses Prettier for JS/TS formatting
```

## Clean

```bash
# Remove all build artifacts
./gradlew clean

# This deletes:
# - build/ directory
# - compiled classes
# - test outputs
# - generated sources

# Rebuild from scratch
./gradlew clean build
```

## Production Build

```bash
# Release build variant
./gradlew assembleRelease  # For Android

# Or general production build
./gradlew clean build

# Generate JAR/AAR
./gradlew jar              # Java JAR
./gradlew assemble         # Android AAR/APK

# This project doesn't deploy Gradle builds directly
```

## Troubleshooting

```bash
# Common issues
# "gradlew: Permission denied" - chmod +x gradlew
# "Gradle DSL method not found" - version mismatch in build.gradle
# "Could not find method compile()" - outdated Gradle version

# Memory issues
# Set Gradle memory via Gradle properties or env
export GRADLE_OPTS="-Xmx512m"

# Offline mode (no network)
./gradlew build --offline

# Debug output
./gradlew --info    # Detailed output
./gradlew --debug   # Debug-level output
```