# Python

Reference commands for Python development. Not part of this project's runtime but useful for DevOps and automation tasks.

## Version Check

```bash
python3 --version
python --version      # May point to Python 2 on some systems
pip --version
```

## Installation

```bash
# macOS
brew install python3

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y python3 python3-pip

# Windows: Download from python.org

# Using pyenv (recommended for version management)
pyenv install 3.11
pyenv global 3.11
pyenv versions

# pip install --upgrade pip
```

## Hello World

```bash
echo "print('Hello, World!')" > hello.py
python3 hello.py
```

## Dependency/Package Installation

```bash
# Install a package
pip install <package>

# Install with version constraint
pip install "package>=1.0,<2.0"

# Install from requirements file (this project uses pip)
pip install -r requirements.txt

# Install in editable mode for development
pip install -e .

# Upgrade pip
pip install --upgrade pip

# List installed packages
pip list

# Outdated packages
pip list --outdated
```

## Build

Python is generally interpreted, but you can create executables:

```bash
# PyInstaller (create standalone executables)
pip install pyinstaller
pyinstaller --onefile --windowed script.py

# cx_Freeze alternative
pip install cx-Freeze
cx_Freeze --script script.py

# This project doesn't use compiled Python builds
```

## Run

```bash
# Simple script execution
python3 script.py

# With arguments
python3 script.py arg1 arg2

# Interactive mode
python3          # Python REPL
python3 -i script.py  # Run script and enter interactive mode

# This project doesn't use Python as a runtime
```

## Test

```bash
# Using pytest (standard Python test framework)
pytest                              # Run all tests in current directory
pytest -v                           # Verbose output
pytest -k "test_name"               # Run tests matching name
pytest -x                           # Stop on first failure
pytest --coverage                   # With coverage report

# This project uses Jest/Node.js for testing, not pytest
# But pytest is useful for infrastructure/shell scripts
```

## Lint

```bash
# Using flake8 (popular Python linter)
flake8 script.py

# Using pylint
pylint script.py

# With autofix (where possible)
autopep8 --in-place script.py

# This project uses ESLint/Prettier for JS, not Python linters
```

## Format

```bash
# Using autopep8
autopep8 --in-place --aggressive --aggressive script.py

# Using black (popular formatter)
black script.py

# Using autopep8 with this project
black .  # Run on entire codebase
```

## Clean

```bash
# Remove __pycache__ directories
find . -type d -name __pycache__ -exec rm -rf {} +

# Remove .pyc files
find . -type f -name "*.pyc" -delete

# Remove pytest cache
rm -rf .pytest_cache

# Clean pip cache
pip cache purge
```

## Production Build

```bash
# Create standalone executable with PyInstaller
pyinstaller --onefile --name "my-app" script.py

# Or use containerization (this project's approach)
# Deploy Python apps via Docker for reproducibility
```