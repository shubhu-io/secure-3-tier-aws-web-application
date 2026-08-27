# C++

Reference commands for C++ development. Not part of this project's runtime but useful for systems programming, game development, and performance-critical systems.

## Version Check

```bash
g++ --version
clang++ --version     # Alternative compiler
```

## Installation

```bash
# macOS
brew install llvm          # Provides clang++
# Or: brew install gcc        # Provides g++

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y g++ build-essential

# Fedora
sudo dnf install -y gcc-c++

# Windows: Use MinGW, TDM-GCC, or Visual Studio

# SDKMAN (optional)
sdk install gcc
```

## Hello World

```bash
# Create hello.cpp
cat > hello.cpp << 'EOF'
#include <iostream>

int main() {
    std::cout << "Hello, World!" << std::endl;
    return 0;
}
EOF

# Compile
g++ hello.cpp -o hello

# Run
./hello
```

## Installation & Setup

```bash
# Ensure C++ compiler is installed
# Verify: g++ --version or clang++ --version

# Common IDEs: VS Code, CLion, Visual Studio

# This project doesn't use C++ directly
```

## Build

```bash
# Compile C++ file
g++ hello.cpp -o hello

# With C++17 standard (recommended)
g++ -std=c++17 hello.cpp -o hello

# With C++20 standard
g++ -std=c++20 hello.cpp -o hello

# With warning flags (best practice)
g++ -Wall -Wextra -Werror -std=c++17 hello.cpp -o hello

# With debug symbols
g++ -g -std=c++17 hello.cpp -o hello

# With optimization
g++ -O2 -std=c++17 hello.cpp -o hello

# Compile multiple files
g++ -o app main.cpp utils.cpp math.cpp -std=c++17

# This project doesn't use C++ build steps
```

## Run

```bash
# Execute compiled binary
./hello

# With arguments
./hello arg1 arg2

# With debug symbols
gdb ./hello

# This project doesn't use C++ runtime
```

## Test

C++ uses similar testing approaches to C:

```bash
# Using Google Test (gtest)
# Set up gtest and write test files

# Manual verification
./hello          # Run and check output

# This project doesn't use C++ testing
```

## Lint

```bash
# Using clang-tidy (recommended for C++ static analysis)
clang-tidy hello.cpp -checks=modernize-*

# Using cpplint
cpplint.py hello.cpp

# Using GCC warnings
g++ -Wall -Wextra -Werror -c hello.cpp

# This project doesn't use C++ linting
```

## Format

```bash
# Using clang-format (standard C++ formatter)
clang-format -i hello.cpp

# Using indent
indent -linux hello.cpp

# This project doesn't use C++ formatting (uses Prettier/ESLint for JS)
```

## Clean

```bash
# Remove compiled binaries and object files
rm -f hello *.o

# Remove all generated files
rm -f app a.out

# Using Makefile
make clean        # If Makefile present

# This project doesn't use C++ directly
```

## Production Build

```bash
# Optimized build for production
g++ -O3 -s -DNDEBUG -std=c++17 hello.cpp -o hello

# Strip debug symbols
strip hello

# Create shared library
g++ -shared -fPIC -o libhello.so hello.cpp

# This project doesn't deploy C++ binaries
```

## Troubleshooting

```bash
# Common errors
# "g++: command not found" - install build-essential or LLVM
# "error: expected identifier before 'token'" - syntax issue
# "undefined reference to..." - linking issue, add -lm for math

# Debugging
g++ -g -o hello hello.cpp  # Build with debug symbols
gdb ./hello            # GNU Debugger

# Environment
g++ --version        # Check compiler version
which g++            # Verify compiler location
```