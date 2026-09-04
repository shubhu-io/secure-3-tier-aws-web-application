SHELL := /bin/bash

# ── deployment defaults (override via env or .env.aws) ──────────────────────
REGION     ?= eu-west-1
ENV_NAME   ?= dev
PROJECT    ?= secure-ntier
TAG        ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo latest)

.PHONY: help \
	 prereqs bootstrap \
	 deploy-aws push-aws tf-init tf-plan tf-apply tf-destroy \
	 local-up local-down local-reset \
	 build-node test-node build-typescript test-typescript \
	 build-python test-python \
	 build-java-maven test-java-maven build-java-gradle test-java-gradle \
	 build-go test-go build-rust test-rust \
	 build-cpp test-cpp build-csharp test-csharp \
	 build-php test-php build-ruby test-ruby

help:
	@echo ""
	@echo "  ╔══════════════════════════════════════════════════════════╗"
	@echo "  ║          secure-ntier  —  Makefile targets               ║"
	@echo "  ╚══════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "  ── AWS EC2 Deployment ──────────────────────────────────────"
	@echo "  make prereqs                 Verify all tools are installed"
	@echo "  make bootstrap               Create S3 state bucket + DynamoDB lock"
	@echo "  make deploy-aws              Full end-to-end deploy to AWS EC2"
	@echo "  make push-aws                Build + push images + roll ASG (no terraform)"
	@echo ""
	@echo "  ── Terraform ───────────────────────────────────────────────"
	@echo "  make tf-init                 terraform init (AWS backend)"
	@echo "  make tf-plan                 terraform plan  -var cloud=aws"
	@echo "  make tf-apply                terraform apply -var cloud=aws"
	@echo "  make tf-destroy              terraform destroy (deletes all AWS resources)"
	@echo ""
	@echo "  ── Local Development (no AWS) ──────────────────────────────"
	@echo "  make local-up                docker compose up --build (background)"
	@echo "  make local-down              docker compose down"
	@echo "  make local-reset             docker compose down -v + up (wipe DB)"
	@echo ""
	@echo "  ── Code Examples ───────────────────────────────────────────"
	@echo "  make build-node / test-node"
	@echo "  make build-python / test-python"
	@echo "  make build-go / test-go"
	@echo "  make build-java-maven / test-java-maven"
	@echo "  (and more — see below)"
	@echo ""

# ── Prerequisites ─────────────────────────────────────────────────────────────
prereqs:
	@bash scripts/setup.sh

# ── Bootstrap state backend ───────────────────────────────────────────────────
bootstrap:
	@bash terraform/scripts/bootstrap-state.sh $(REGION)

# ── Full end-to-end EC2 deploy ────────────────────────────────────────────────
deploy-aws:
	@bash scripts/deploy-to-ec2.sh $(REGION) $(ENV_NAME) $(PROJECT)

# ── Build + push + roll ASG (no terraform re-apply) ──────────────────────────
push-aws:
	@bash cicd/scripts/registry-login.sh $(REGION)
	@bash cicd/scripts/stack-push.sh $(TAG) $(REGION) $(PROJECT) $(ENV_NAME)
	@bash cicd/scripts/deploy-ec2.sh $(TAG) $(REGION) $(ENV_NAME) $(PROJECT)

# ── Terraform targets ─────────────────────────────────────────────────────────
tf-init:
	@cd terraform && terraform init \
		-backend-config="cloud/aws/backend.hcl" \
		-backend-config="key=aws/$(ENV_NAME)/terraform.tfstate" \
		-backend-config="region=$(REGION)"

tf-plan:
	@cd terraform && terraform plan \
		-var="cloud=aws" \
		-var-file="environments/$(ENV_NAME)/terraform.tfvars"

tf-apply:
	@cd terraform && terraform apply \
		-var="cloud=aws" \
		-var-file="environments/$(ENV_NAME)/terraform.tfvars"

tf-destroy:
	@cd terraform && terraform destroy \
		-var="cloud=aws" \
		-var-file="environments/$(ENV_NAME)/terraform.tfvars"

# ── Local dev (Docker Compose, no AWS) ───────────────────────────────────────
local-up:
	@bash scripts/local-up.sh

local-down:
	@bash scripts/local-up.sh --down

local-reset:
	@bash scripts/local-up.sh --reset

# ═════════════════════════════════════════════════════════════════════════════
# Code example targets (unchanged)
# ═════════════════════════════════════════════════════════════════════════════

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