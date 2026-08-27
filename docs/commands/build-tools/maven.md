# Maven

Reference commands for Maven build system. Not part of this project's runtime (which uses npm/yarn) but essential for Java/Ecosystem DevOps.

## Installation

```bash
# macOS
brew install maven

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y maven

# Fedora
sudo dnf install -y maven

# Windows: Download from apache.org or use SDKMAN

# SDKMAN (recommended)
sdk install maven
```

## Version Check

```bash
mvn --version
```

## Dependency/Package Management

Maven uses `pom.xml` for project configuration:

```bash
# Install dependencies (defined in pom.xml)
mvn install

# Install without running tests
mvn install -DskipTests

# Update project dependencies (from remote repositories)
mvn dependency:resolve

# Check for dependency updates
mvn versions:displayDependencyUpdates

# Exclude transitive dependencies (in pom.xml <exclusions>)
```

## Build

```bash
# Compile the project
mvn compile

# Full build (compile + test + package)
mvn clean install

# Clean build (recommended before commits/releases)
mvn clean

# Skip tests during build
mvn clean install -DskipTests

# Compile only (no tests, no packaging)
mvn compile
```

## Run

Maven itself doesn't "run" the project directly, but you can:

```bash
# Run with Maven Exec Plugin (if configured)
mvn exec:java -Dexec.mainClass="com.example.Main" -Dexec.args="arg1"

# Or run via Java directly after compilation
java -cp target/classes com.example.Main
```

## Test

```bash
# Run all tests
mvn test

# Run specific test class
mvn test -Dtest=com.example.MyTest

# Run specific test method
mvn test -Dtest=MyTest#methodName

# Skip tests
mvn clean install -DskipTests

# Filter tests by group
mvn test -Dtest="*IT*"  # Integration tests

# This project doesn't use Maven testing
```

## Lint / Code Quality

```bash
# Enforce code conventions
mvn checkstyle:check

# Findbugs (code analysis)
mvn findbugs:check

# PMD (code analysis)
mvn pmd:check

# This project doesn't use Maven linting
```

## Format

Maven doesn't format code directly; it relies on plugins or IDEs:

```bash
# Use Google Java Format plugin
# Or configure checkstyle (see Lint section)

# This project uses Google Java Format via IDE or checkstyle
```

## Clean

```bash
# Remove all build artifacts
mvn clean

# This deletes:
# - target/ directory (compiled classes)
# - generated sources
# - JAR/WAR files

# Rebuild from scratch
mvn clean install
```

## Production Build

```bash
# Create production JAR (with dependencies)
mvn clean package

# Create JAR with all dependencies included
mvn clean package -Dmaven.jar.runfurther=true

# Or use Maven Assembly Plugin
# mvn clean assembly:single

# Deploy to repository
mvn clean deploy
```

## Troubleshooting

```bash
# Common issues
# "mvn: command not found" - install Maven, verify PATH
# "Plugin execution not covered" - plugin version conflict
# "Failed to resolve artifact" - network issue, check Maven settings.xml

# Memory issues (large projects)
# Set Maven memory in ~/.m2/settings.xml or via env
export MAVEN_OPTS="-Xmx512m -XX:MaxPermSize=128m"

# Debug mode
mvn -X          # Full debug output
mvn -e          # Error output with stack trace
```