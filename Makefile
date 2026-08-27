SHELL := /bin/bash

.PHONY: help build test clean \
    build-node test-node build-typescript test-typescript \
    build-python test-python \
    build-java-maven test-java-maven build-java-gradle test-java-gradle \
    build-go test-go build-rust test-rust \
    build-cpp test-cpp build-csharp test-csharp \
    build-php test-php build-ruby test-ruby

help:
	@echo "Available targets:"
	@echo "  make help           - Show this help"
	@echo "  make build-node     - Build JavaScript example"
	@echo "  make test-node      - Test JavaScript example"
	@echo "  make build-typescript  - Build TypeScript example"
	@echo "  make test-typescript - Test TypeScript example"
	@echo "  make build-python   - Build Python example"
	@echo "  make test-python    - Test Python example"
	@echo "  build-java-maven    - Build Java Maven example"
	@echo "  test-java-maven     - Test Java Maven example"
	@echo "  build-java-gradle   - Build Java Gradle example"
	@echo "  test-java-gradle    - Test Java Gradle example"
	@echo "  build-go            - Build Go example"
	@echo "  test-go             - Test Go example"
	@echo "  build-rust          - Build Rust example"
	@echo "  test-rust           - Test Rust example"
	@echo "  build-cpp           - Build C++ example"
	@echo "  test-cpp            - Test C++ example"
	@echo "  build-csharp        - Build C# example"
	@echo "  test-csharp         - Test C# example"
	@echo "  build-php           - Build PHP example"
	@echo "  test-php            - Test PHP example"
	@echo "  build-ruby          - Build Ruby example"
	@echo "  test-ruby           - Test Ruby example"

# JavaScript
build-node:
	@cd examples/programming/javascript && npm install

test-node:
	@cd examples/programming/javascript && npm test

# TypeScript
build-typescript:
	@cd examples/programming/typescript && npm install

test-typescript:
	@cd examples/programming/typescript && npm test

# Python
build-python:
	@cd examples/programming/python && python -m venv .venv && . .venv/bin/activate && pip install -r requirements.txt

test-python:
	@cd examples/programming/python && . .venv/bin/activate && pytest

# Java Maven
build-java-maven:
	@cd examples/programming/java-maven && mvn clean compile

test-java-maven:
	@cd examples/programming/java-maven && mvn test

# Java Gradle
build-java-gradle:
	@cd examples/programming/java-gradle && ./gradlew build

test-java-gradle:
	@cd examples/programming/java-gradle && ./gradlew test

# Go
build-go:
	@cd examples/programming/go && go mod tidy

test-go:
	@cd examples/programming/go && go test ./...

# Rust
build-rust:
	@cd examples/programming/rust && cargo build

test-rust:
	@cd examples/programming/rust && cargo test

# C++
build-cpp:
	@cd examples/programming/cpp && cmake -S . -B build && cmake --build build

test-cpp:
	@ctest --test-dir build

# C#
build-csharp:
	@cd examples/programming/csharp && dotnet restore

test-csharp:
	@cd examples/programming/csharp && dotnet test

# PHP
build-php:
	@cd examples/programming/php && composer install

test-php:
	@cd examples/programming/php && composer test

# Ruby
build-ruby:
	@cd examples/programming/ruby && bundle install

test-ruby:
	@cd examples/programming/ruby && bundle exec rspec