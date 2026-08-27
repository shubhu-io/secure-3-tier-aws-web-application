# Go (Golang)

Reference commands for Go development. Not part of this project's runtime but useful for DevOps, cloud tools, and infrastructure automation.

## Version Check

```bash
go version
```

## Installation

```bash
# macOS
brew install go

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y golang-go

# Windows: Download installer from go.dev

# Using sdkman (optional)
sdk install go
```

## Hello World

```bash
# Create a Go module and hello program
go mod init hello
cat > hello.go << 'EOF'
package main

import "fmt"

func main() {
    fmt.Println("Hello, World!")
}
EOF

# Run directly
go run hello.go

# Build executable
go build -o hello hello.go
./hello
```

## Installation & Setup

```bash
# Initialize a Go module
go mod init myproject

# Set up Go workspace
go env -w GO111MODULE=on
go env -w GOPATH=~/go
```

## Dependency/Package Installation

```bash
# Install a package (downloads and adds to go.mod)
go get <package>

# Install specific version
go get github.com/some/package@v1.2.3

# Remove a package
go remove <package>

# Verify dependencies
go mod tidy

# Update all dependencies
go get -u ./...

# Verify module cache
go mod verify
```

## Build

```bash
# Build the current project
go build

# Build with output name
go build -o myapp

# Build for specific OS/architecture
GOOS=linux GOARCH=amd64 go build -o myapp-linux

# Cross-compilation examples
GOOS=windows GOARCH=amd64 go build -o myapp.exe
GOOS=darwin GOARCH=amd64 go build -o myapp-mac

# This project uses Go for some cloud tools and operators
```

## Run

```bash
# Run the Go program
go run main.go

# Or build first then execute
go build -o app && ./app
```

## Test

```bash
# Run all tests
go test

# Verbose output
go test -v

# Run tests matching pattern
go test -run "TestFunction"

# With coverage
go test -cover

# With race detector
go test -race

# This project doesn't use Go testing directly, but go test is essential
# for Go-based infrastructure tools (Terraform provider plugins, etc.)
```

## Lint

```bash
# Using golangci-lint (standard linter runner)
golangci-lint run

# Or individual linters
go vet          # Built-in static analysis
staticcheck     # Third-party enhanced linting

# Install golangci-lint
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
```

## Format

```bash
# Go fmt (built-in formatter)
go fmt          # Formats all Go files in current directory and subdirectories

# gofmt (the underlying tool)
gofmt -w .      # Write formatted files to disk

# This project uses go fmt for Go code, but primary code is JavaScript/TypeScript
```

## Clean

```bash
# Remove compiled files and cache
go clean

# Remove object files and cached files
go clean -cache
go clean -modcache

# Remove build artifacts
rm -f myapp       # Your compiled binary

# Go mod tidy to clean up go.mod/go.sum
go mod tidy
```

## Production Build

```bash
# Build static binary for deployment
GOOS=linux GOARCH=amd64 go build -o myapp .

# Or use UPX to compress
upx myapp

# Or build multi-stage Docker image (this project's approach for Go tools)
# Most Go infrastructure tools are compiled binaries deployed directly
```

## Troubleshooting

```bash
# Common issues
# "go: missing Go.mod file" - run `go mod init <module-name>`
# "go: go.mod module name uses old-style repository layout" - run go mod tidy
# "cannot find package" - ensure GOPATH is set correctly, or use modules

# Version management
go env GOVERSION   # Check Go version
go env GOPATH      # Check Go path

# Upgrade Go
go get -u golang.org/dl/go1.21
go1.21 download    # Download specific Go version if using goenv/goenv
```