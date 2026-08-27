# Docker Compose

Reference commands for Docker Compose. This project uses Docker Compose for local development and CI/CD.

## Installation

```bash
# macOS
brew install docker-compose   # Or docker compose (v2, built-in)

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y docker-compose

# Windows: Docker Desktop includes compose (v2)

# Verify (Docker Compose v2 is plugin, v1 is standalone)
docker compose version      # v2 (recommended)
docker-compose version      # v1 (legacy)

# On newer Docker Desktop/Engine, use:
docker compose --help
```

## Version Check

```bash
docker compose version   # v2 (recommended, built into docker command)
docker-compose version   # v1 (legacy standalone)
```

## This Project's docker-compose.yml

The repository includes `docker-compose.yml` for local development:

```yaml
# application/docker-compose.yml
services:
  frontend:
    build: ./frontend
    ports:
      - "3000:80"
    environment:
      - NODE_ENV=development
    volumes:
      - ./frontend:/app
      - /app/node_modules

  backend:
    build: ./backend
    ports:
      - "5000:5000"
    environment:
      - NODE_ENV=development
      - DATABASE_URL=postgresql://postgres:postgres@db:5432/app_db
    volumes:
      - ./backend:/app
      - /app/node_modules

  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=app_db
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  # Optional: phpMyAdmin for visual DB management
  # pma:
  #   image: phpmyadmin/phpmyadmin
  #   environment:
  #     - PMA_HOST=db
  #     - PORT=8080
  #   ports:
  #     - "8080:80"

volumes:
  postgres_data:
```

## Services

```bash
# Start all services (detached mode)
docker compose up -d

# Start and show logs
docker compose up          # (no -d, shows logs in terminal)

# Stop all services
docker compose down

# Stop and remove volumes (including data)
docker compose down -v

# Restart all services
docker compose restart

# Stop without removing containers
docker compose stop

# Remove stopped containers
docker compose rm
```

## Service Management

```bash
# Start specific service
docker compose up -d frontend

# Start specific service with dependencies
docker compose up -d db backend

# Stop specific service
docker compose stop frontend

# Remove specific service
docker compose rm frontend

# View status of all services
docker compose ps

# View status of specific service
docker compose ps frontend

# View logs from specific service
docker compose logs frontend

# Follow logs (real-time)
docker compose logs -f frontend

# Follow logs from all services
docker compose logs -f

# Recreate service (after code changes)
docker compose up -d --force-recreate frontend

# Recreate and reattach
docker compose up -d
```

## Build

```bash
# Build (rebuild) images
docker compose build

# Build with no cache
docker compose build --no-cache

# Rebuild specific service
docker compose build frontend

# Rebuild and start
docker compose up -d --build
```

## Exec & Shell

```bash
# Execute command in running service
docker compose exec frontend bash

# Execute command as another user
docker compose exec -u root frontend bash

# Show running processes in container
docker compose exec frontend ps aux

# This project's usage:
# - exec into backend container for debugging
# - run database migrations
# - check node processes
```

## Troubleshooting

```bash
# Common issues
# "docker-compose: command not found" - ensure Docker Desktop (v20.10+) or v1 installed
# "docker compose" vs "docker-compose" - use docker compose (v2) on newer Docker
# "Error: toils.io/video/api" - outdated compose file version
# "Conflict with another container" - port already in use

# Debug
docker compose config     # Validate compose file syntax
docker compose pictures   # Debug rendering issues

# Cleanup
docker compose down -v    # Stop and remove volumes (data too)
docker system prune -a    # Remove all unused resources

# This project development workflow:
# docker compose up -d     # Start dev environment
# docker compose logs -f   # Watch logs
# docker compose down -v   # Stop and clean up
```