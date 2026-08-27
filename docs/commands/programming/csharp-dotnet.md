# C# (.NET)

Reference commands for C# and .NET development. Not part of this project's runtime but useful for Windows/.NET environments, cloud services, and general DevOps.

## Version Check

```bash
dotnet --version
csharp-version       # If using specific tooling
```

## Installation

```bash
# macOS
brew install --cask dotnet-sdk

# Ubuntu/Debian
# Microsoft repository
sudo apt-get update
sudo apt-get install -y dotnet-sdk-21.0

# Fedora
sudo dnf install dotnet-sdk

# Windows: Download .NET SDK from dotnet.microsoft.com

# SDKMAN (optional)
sdk install dotnet 21.0.403
```

## Hello World

```bash
# Create a console application
dotnet new console -n HelloWorld
cd HelloWorld

# Using C# file directly
cat > Program.cs << 'EOF'
using System;

class Program {
    static void Main(string[] args) {
        Console.WriteLine("Hello, World!");
    }
}
EOF

# Run
dotnet run
# Or: dotnet run --args arg1 arg2
```

## Installation & Setup

```bash
# .NET versions this project may reference
# dotnet --list-runtimes   # List installed runtimes
# dotnet --list-sdks       # List installed SDKs

# Path setup
# On macOS/Linux: export PATH="$PATH:/usr/local/share/dotnet"
# On Windows: Add to system PATH during install

# .NET Versions
# sdk install dotnet 8.0
# sdk install dotnet 9.0
# sdk install dotnet 21.0   # Latest Long Term Support
```

## Dependency/Package Management (.NET)

```bash
# Install NuGet package
dotnet add package <package-name>

# Install specific version
dotnet add package Newtonsoft.Json --version 13.0.3

# Remove package
dotnet remove package <package-name>

# Update packages
dotnet package update

# List installed packages
dotnet list package

# Pack your project into a NuGet package
dotnet pack

# This project doesn't use .NET directly
```

## Build

```bash
# Build the project
dotnet build

# Build in Release mode (production)
dotnet build -c Release

# Build with specific framework
dotnet build -f net8.0

# Publish for deployment
dotnet publish -c Release -o ./publish output

# This project uses Node.js/TypeScript, not .NET runtime
```

## Run

```bash
# Run the .NET application
dotnet run          # Builds and runs in one step
dotnet run --args arg1 arg2

# Run compiled binary (after dotnet publish)
./bin/Release/net8.0/<appname>

# This project doesn't use .NET as runtime
```

## Test

```bash
# Using xUnit (standard .NET test framework)
dotnet test                 # Run all tests
dotnet test -c Release      # Run in Release configuration
dotnet test --filter "TestName"  # Run specific test

# Using NUnit
dotnet new nunit          # Create NUnit test project
dotnet test --framework net8.0

# Using MSTest
dotnet test --logger "trx;LogFileName=test.trx"

# This project uses Jest for JavaScript testing, not .NET testing
```

## Lint / Code Quality

```bash
# Using dotnet-code-analysis (built-in)
dotnet build          # Runs analysis by default

# Using StyleCop
dotnet tool install -g dotnet-stylist

# .editorconfig is used for code style consistency
# This project doesn't use .NET linting (uses ESLint/Prettier for JS)
```

## Format

```bash
# Using dotnet-format
dotnet format          # Formats all files in the solution

# Using editorconfig
# Visual Studio Code and IDEs respect .editorconfig automatically

# This project uses Prettier for JS/TS formatting
```

## Clean

```bash
# Remove build artifacts
rm -rf bin/ obj/

# Using .NET commands
dotnet clean          # Clean build outputs

# Remove published output
rm -rf publish/

# This project doesn't use .NET build artifacts
```

## Production Build

```bash
# Publish as self-contained executable
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish

# Publish as framework-dependent
dotnet publish -c Release -o ./publish

# Create Docker image (this project's approach for .NET if needed)
# docker build -t myapp .

# This project uses containers rather than native .NET deployment
```

## Troubleshooting

```bash
# Common issues
# "dotnet: command not found" - install .NET SDK, verify PATH
# "NETSDK1045" - missing SDK version, install correct dotnet-sdk
# "Project file not found" - cd to project directory or specify full path

# Debugging
dotnet list packages    # Check installed NuGet packages
dotnet list extensions  # Check installed .NET extensions

# .NET CLI help
dotnet --help          # Show all CLI commands
dotnet new --help      # Create new projects
```