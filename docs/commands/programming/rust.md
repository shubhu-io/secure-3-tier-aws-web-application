# Rust

Reference commands for Rust development. Not part of this project's runtime but useful for systems programming, command-line tools, and infrastructure automation (including some cloud tools).

## Version Check

```bash
rustc --version
cargo --version
rustup --version
```

## Installation

```bash
# macOS
brew install rustup
rustup update

# Ubuntu/Debian
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Windows: Download rustup from rust-lang.org

# SDKMAN (optional)
sdk install rust
```

## Hello World

```bash
# Create a new binary project
cargo new hello_world
cd hello_world

# Run immediately
cargo run

# Build executable
cargo build

# Run built binary
./target/hello_world
```

## Installation & Setup

```bash
# Rust toolchain via rustup (recommended)
# rustup provides: rustc (compiler), cargo (build system), rustup (updater)

# Default installation puts binaries in:
# $HOME/.cargo/bin/

# Verify installation
which cargo
which rustc

# Default stable version
rustup default stable

# List installed toolchains
rustup list

# Update rustup and Rust
rustup update

# Install specific version
rustup install 1.77.0
rustup default 1.77.0
```

## Dependency/Package Management

Rust uses Cargo as its package manager. All dependency commands are run via Cargo:

```bash
# Add a dependency (updates Cargo.toml and downloads)
cargo add <package>

# Add specific version
cargo add serde --version 1.0.200

# Add as dev dependency
cargo add serde --dev

# Remove a dependency
cargo remove <package>

# Update all dependencies
cargo update

# Verify the dependency tree
cargo tree

# Build only (don't run)
cargo build

# Check for errors without producing output
cargo check

# This project doesn't use Rust directly
```

## Build

```bash
# Build the project
cargo build

# Build in release mode (production, optimized)
cargo build --release

# Build for deployment
cargo build --release --bin <binary-name>

# Check for compilation errors without building
cargo check

# This project doesn't use Rust build steps directly
```

## Run

```bash
# Run the project (builds + executes)
cargo run

# Run with arguments
cargo run -- arg1 arg2

# Run specific binary in multi-project workspace
cargo run --bin <binary-name>

# This project doesn't use Rust runtime
```

## Test

```bash
# Run all tests
cargo test

# Verbose output
cargo test -v

# Run specific test
cargo test -- test_name

# With code coverage
cargo tarpaulin  # Requires commercial license, use grcov for free

# With code coverage (free)
grcov . --binary-path target/debug/ -t html --prefix /your/path -o coverage/

# Run tests with race detector (if applicable)
# Rust tests are single-threaded by default, but can use --threads

# This project doesn't use Rust testing
```

## Lint

```bash
# Using clippy (built-in linter for Rust)
cargo clippy

# With suggestions auto-applied
cargo clippy --all-targets -- -D warnings

# Install clippy if not included
rustup component add clippy

# This project doesn't use Rust linting (uses ESLint/Prettier for JS)
```

## Format

```bash
# Using rustfmt (built-in formatter)
cargo fmt           # Formats all Rust files in the project

# Format specific file
rustfmt --write main.rs

# This project doesn't use Rust formatting (uses Prettier for JS/TS)
```

## Clean

```bash
# Remove build artifacts and target directory
cargo clean

# Remove Cargo cache
rm -rf ~/.cargo/registry/src/*

# Remove target directory
rm -rf target/

# Remove Cargo lock file (re-download on next build)
rm -f Cargo.lock

# Rebuild from scratch
cargo build
```

## Production Build

```bash
# Release build (optimized, stripped)
cargo build --release

# The --release flag:
# - Enables optimizations (LLVM optimizations)
# - Strips debug symbols
# - Produces smaller faster binaries

# Typical production deployment
cargo build --release -o my-app
./target/release/my-app

# Or cross-compile for specific target
cargo build --release --target x86_64-unknown-linux-gnu

# This project uses containers (Docker) for Go/Rust tooling, not direct binary deployment
```

## Troubleshooting

```bash
# Common issues
# "rustc: command not found" - install Rust via rustup.sh
# "cannot find package" - ensure Cargo.toml is correct, run cargo update
# "unresolved dependency" - run cargo update, check Cargo.toml versions

# Common errors
# "error: linking with gcc failed" - ensure C compiler is available
# "missing `Cargo.toml`" - run in project directory with Cargo.toml

# Version management
rustup show    # Show installed toolchains
rustup update  # Update to latest stable

# Debug builds
RUST_BACKTRACE=1 cargo run   # Show backtrace on panic
```