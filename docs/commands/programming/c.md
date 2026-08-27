# C

Reference commands for C development. Not part of this project's runtime but useful for systems programming, embedded systems, and general DevOps tasks.

## Version Check

```bash
gcc --version
clang --version     # Alternative compiler
```

## Installation

```bash
# macOS
brew install gcc          # Or Xcode Command Line Tools: xcode-select --install

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y gcc build-essential

# Fedora
sudo dnf install gcc

# Windows: Use MinGW or TDM-GCC

# SDKMAN (optional)
sdk install gcc
```

## Hello World

```bash
# Create hello.c
cat > hello.c << 'EOF'
#include <stdio.h>

int main() {
    printf("Hello, World!\n");
    return 0;
}
EOF

# Compile
gcc hello.c -o hello

# Run
./hello
```

## Installation & Setup

```bash
# Install build essentials
# Ubuntu: sudo apt-get install build-essential
# macOS: xcode-select --install provides gcc/clang

# PATH should include /usr/bin/gcc or /usr/local/bin/gcc

# Alternative: clang compiler
# brew install llvm  # on macOS
# sudo apt-get install clang   # on Ubuntu
```

## Build

```bash
# Compile C file
gcc hello.c -o hello

# With warning flags (recommended)
gcc -Wall -Wextra -o hello hello.c

# With debug symbols
gcc -g -o hello hello.c

# With optimization
gcc -O2 -o hello hello.c

# Compile multiple files
gcc -o app main.c utils.c math.c

# This project doesn't use C directly
```

## Run

```bash
# Execute compiled binary
./hello

# With arguments
./hello arg1 arg2

# Run with Valgrind (memory analysis)
valgrind ./hello

# This project doesn't use C runtime
```

## Test

C uses different testing approaches:

```bash
# Using CUnit (unit testing framework)
# Requires separate installation and setup

# Using Google Test (gtest) - C++ framework, can be used with C
# gtest sample test

# Manual testing
./hello          # Run and verify output

# This project uses JavaScript/Node.js testing, not C testing
```

## Lint

```bash
# Using splint (secure C code checker)
splint hello.c

# Using lint
lint hello.c

# Static analysis with GCC warnings
gcc -Wall -Wextra -Werror -c hello.c  # Check for warnings

# This project doesn't use C linting
```

## Format

C doesn't have a built-in formatter, but you can use:

```bash
# Using clang-format (recommended)
clang-format -i hello.c

# Using indent
indent -linux hello.c

# This project doesn't use C formatting
```

## Clean

```bash
# Remove compiled binaries and object files
rm -f hello *.o

# Remove executable
rm -f hello

# Using Makefile (standard approach)
make clean        # If Makefile is present

# Remove backup files
rm -f *~ hello.c~
```

## Production Build

```bash
# Cross-compilation
arm-linux-gnueabihf-gcc -o app app.c

# Static binary
gcc -static -o app app.c

# Strip debug symbols for smaller binary
strip app

# This project doesn't deploy C binaries
```

## Troubleshooting

```bash
# Common errors
# "gcc: command not found" - install build-essential or Xcode CLI tools
# "undefined reference to..." - link missing libraries (-lm for math)
# "return type of 'main' is not int" - main must return int

# Debugging
gcc -g -o hello hello.c  # Add debug symbols
gdb ./hello        # GNU Debugger

# Version check
gcc --version      # Verify GCC version
```