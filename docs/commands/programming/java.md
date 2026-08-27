# Java

Reference commands for Java development. Not part of this project's runtime but useful for general DevOps and enterprise tasks.

## Version Check

```bash
java --version
javac --version
```

## Installation

```bash
# macOS
brew install openjdk@21
# Add to PATH: echo 'export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"' >> ~/.zshrc

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y openjdk-21-jdk

# Windows: Download JDK from oracle.net or use SDKMAN

# Using SDKMAN (recommended)
sdk install java 21.0.2-open
sdk default java 21.0.2-open
```

## Hello World

```bash
# Create Java file
cat > Hello.java << 'EOF'
public class Hello {
    public static void main(String[] args) {
        System.out.println("Hello, World!");
    }
}
EOF

# Compile
javac Hello.java

# Run
java Hello
```

## Installation & Setup

```bash
# Set JAVA_HOME (example for Ubuntu)
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

# Or with SDKMAN
sdk install java 21.0.2-open
```

## Dependency/Package Management

Java uses build tools for dependency management:

```bash
# Maven
mvn install
mvn compile
mvn clean

# Gradle
gradle build
gradle dependencies

# This project doesn't use Java, but these are standard commands
```

## Build

```bash
# Compile Java source files
javac Hello.java      # Compiles to Hello.class

# With source directory
javac -d out/ src/Hello.java

# Using Maven (this project's CI may use it)
mvn compile

# Using Gradle
gradle compileJava
```

## Run

```bash
# Run compiled Java class
java Hello

# With command-line arguments
java Hello arg1 arg2

# Using Maven
mvn exec:java -Dexec.mainClass="Hello" -Dexec.args="arg1"

# Using Gradle
gradle run
```

## Test

```bash
# Using JUnit (standard Java test framework)
# Tests are typically in src/test/java/

# Using Maven
mvn test

# Using Gradle
gradle test

# Running specific test
mvn test -Dtest=HelloTest

# This project doesn't use Java testing
```

## Lint

```bash
# Using checkstyle
checkstyle -c sun_checks.xml Hello.java

# Using pmd (code analysis)
pmd -d . -R rulesets/java/quickstart.xml

# This project doesn't use Java linting
```

## Format

Java code formatting is typically handled by IDEs or build tools:

```bash
# Using google-java-format
java -jar google-java-format-1.21.0.jar --replace Hello.java

# This project doesn't use Java formatters
```

## Clean

```bash
# Remove compiled files
rm -rf out/
rm -rf *.class

# Using Maven
mvn clean

# Using Gradle
gradle clean
```

## Production Build

```bash
# Create JAR file
jar cvf myapp.jar -C out/ .

# Or use Maven/Gradle plugins
mvn package

# Or Docker (common for Java apps)
# This project uses containers rather than native Java deployment
```

## Troubleshooting

```bash
# Common issues
# "Error: Could not find or load main class" - check classpath and class name
# "javac: command not found" - install JDK, set JAVA_HOME
# "Error: Unsupported class file version" - update Java version

# Version management
# sdk list java    # List available versions
# sdk install java # Install specific version
```