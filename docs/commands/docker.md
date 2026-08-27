# Docker

Reference commands for Docker. This project uses Docker for containerizing the React frontend, Node.js backend, and PostgreSQL database.

## Installation

```bash
# macOS
brew install docker

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y docker.io

# Add user to docker group (avoids sudo)
sudo usermod -aG $USER docker
newgrp docker

# Windows: Download Docker Desktop from docker.com

# Verify
docker --version

# Start Docker Desktop (macOS/Windows)
# Or start daemon (Linux)
systemctl start docker

# Enable on boot
systemctl enable docker
```

## Version Check

```bash
docker --version
docker version     # Full information including API version
```

## Information

```bash
docker info        # System-wide information
docker system df   # Disk usage summary
```

## Images

```bash
# List all images
docker images

# List images with columns
docker images -a

# Show image details
docker inspect <image-id-or-name>

# Remove an image
docker rmi <image-name-or-id>

# Remove untagged/dangling images
docker image prune

# Remove all unused images
docker image prune -a

# Search for images
docker search <term>

# Pull an image from registry
docker pull nginx:latest

# Push image to registry (requires authentication)
docker tag <image> <registry>/<image>:<tag>
docker push <registry>/<image>:<tag>
```

## Containers

```bash
# Run a container
docker run -d -p 8080:80 nginx:latest

# Run in detached mode (background)
-d

# Map ports (host:container)
-p 8080:80

# Interactive terminal
-it

# Remove container when it exits
--rm

# Set environment variables
-e KEY=value

# Run as non-root user
--user 1000:1000

# This project's Docker usage:
# - Frontend + backend in docker-compose
# - PostgreSQL database container
# - CI/CD uses Docker for builds (Trivy scan, ECR push)

# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# Show container details
docker inspect <container-id-or-name>

# Start a stopped container
docker start <container-id>

# Stop a running container
docker stop <container-id>

# Restart a container
docker restart <container-id>

# Remove a container
docker rm <container-id>

# Remove all stopped containers
docker container prune

# Execute command in running container
docker exec -it <container-id> <command>

# Example: exec into running app container
docker exec -it my-app-container bash

# Show logs from container
docker logs <container-id>

# Follow logs (like tail -f)
docker logs -f <container-id>

# This project's container usage:
# - Frontend React container (Nginx)
# - Backend Node.js container
# - PostgreSQL database container
# - CI/CD build containers (Trivy scanner)
```

## Network

```bash
# List networks
docker network ls

# Create a network (for custom communication)
docker network create my-network

# Connect container to network
docker network connect my-network <container-id>

# Disconnect from network
docker network disconnect my-network <container-id>

# This project uses Docker's default bridge network
# and docker-compose networks for service communication
```

## Volume

```bash
# List volumes
docker volume ls

# Create a volume
docker volume create my-volume

# Remove volumes not used by containers
docker volume prune

# Inspect volume details
docker volume inspect my-volume

# This project uses Docker volumes for:
# - PostgreSQL data persistence
# - Node_modules caching
# - Log storage
```

## Build

```bash
# Build image from Dockerfile in current directory
docker build -t my-image:tag .

# Build with context
docker build -t my-image:tag ./path/to/context

# Build no cache (forces fresh build)
docker build --no-cache -t my-image:tag .

# Build with pull (always pull base image)
docker build --pull -t my-image:tag .

# This project's build:
# - docker build -t secure-ntier/frontend ./docker/frontend
# - docker build -t secure-ntier/backend ./docker/backend

# View build history
docker history <image-id>
```

## This Project's Docker Images

```bash
# Frontend (React + Nginx)
docker build -t secure-ntier/frontend ./docker/frontend

# Backend (Node.js + Express)
docker build -t secure-ntier/backend ./docker/backend

# Full stack with Docker Compose (development)
docker compose up -d       # Start all services
docker compose down        # Stop all services
docker compose build       # Rebuild images
docker compose logs        # Show logs from all services
docker compose ps          # Show status of all services
docker compose restart     # Restart all services
```

## Troubleshooting

```bash
# Common issues
# "docker: command not found" - install Docker Desktop or Docker Engine
# "permission denied" - add user to docker group, or use sudo
# "cannot connect to Docker daemon" - start Docker Desktop/daemon
# "image already exists" use --no-tag or rmi first
# "no space left on device" - cleanup images/volumes/containers

# Cleanup commands
docker system prune -a    # Remove all unused images, containers, networks, build cache
docker system prune       # Remove only stopped containers, dangling images

# Increase disk space
# Delete unused images: docker rmi <image>
# Delete unused volumes: docker volume prune

# Debug
docker version            # Check Docker version and API
info-docker               # System-wide information
```