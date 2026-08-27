# npm

Reference commands for npm (Node Package Manager). This is the primary package manager used in this project (React frontend + Node/Express backend).

## Installation

```bash
# npm comes bundled with Node.js
# Install Node.js (which includes npm):
#   - macOS: brew install node
#   - Ubuntu: sudo apt-get install nodejs npm
#   - Windows: Download from nodejs.org

# Verify npm is installed
npm --version

# Update npm to latest version
npm install -g npm

# Or using nvm (recommended)
nvm install node   # Installs latest Node.js with npm
nvm use node
```

## Version Check

```bash
npm --version
node --version       # Also check Node version (npm depends on it)
```

## Dependency/Package Installation

This project uses npm extensively:

```bash
# Install all dependencies (read from package.json)
npm install

# Install a specific package (adds to package.json and node_modules)
npm install <package-name>

# Install as dev dependency (not produced in production)
npm install --save-dev <package>

# Global installation (tools, not project deps)
npm install -g <package>

# This project's packages:
# - Frontend: npm install in application/frontend/
# - Backend: npm install in application/backend/

# Remove a package
npm uninstall <package>

# Install exact version
npm install <package>@<version>

# Save exact version to package.json
npm install --save-exact <package>
```

## Scripts (This project's npm scripts)

```bash
# View all defined scripts
npm run

# Specific project scripts:
# Frontend (application/frontend/):
npm run dev     # Vite dev server
npm run build   # Vite production build
npm run lint    # ESLint
npm run format  # Prettier

# Backend (application/backend/):
npm test          # Jest tests
npm run lint      # ESLint

# Root level scripts (from repository)
npm test          # Run all tests
```

## Build (This project)

```bash
# Frontend build (React + Vite)
npm run build     # Creates dist/ with compiled assets

# Or direct Vite command
npx vite build

# This project's build output is in:
# - application/frontend/dist/
# - Assets embedded in Docker images
```

## Run (This project)

```bash
# Development mode
npm run dev       # Starts Vite dev server + nodemon

# Production mode
npm start         # As defined in package.json scripts

# This project's run scripts:
# - Frontend: npm run dev (React dev server)
# - Backend: npm start (Node.js Express)
```

## Test (This project)

```bash
# Backend tests (Jest)
npm test          # Runs Jest tests in application/backend/

# Run with verbose output
npm test -- --verbose

# Run specific test file
npm test -- --testPathPattern="auth.test"

# Coverage report
npm test -- --coverage

# This project uses Jest for JavaScript/TypeScript testing
```

## Lint (This project)

```bash
# ESLint (frontend + backend)
npm run lint      # Runs ESLint on all JS/TS files

# Fix lint errors (where possible)
npm run lint -- --fix

# Prettier formatting
npm run format    # Runs Prettier on all files

# This project uses ESLint + Prettier for code quality
```

## Format (This project)

```bash
npm run format    # Runs Prettier --write on all files

# Or direct Prettier
npx prettier --write .
```

## Publish

```bash
# Publish a package to npm registry
npm publish       # (for published packages, not this project)

# Login to npm
npm login

# Set registry
npm config set registry <url>
```

## Clean

```bash
# Remove node_modules (project dependencies)
rm -rf node_modules

# Remove package-lock.json (reinstall from scratch)
rm -f package-lock.json

# Full clean and reinstall
rm -rf node_modules package-lock.json
npm install

# This project's clean pattern (per service):
# - application/frontend/: rm -rf node_modules dist
# - application/backend/: rm -rf node_modules
```

## Troubleshooting

```bash
# Common issues
# "npm: command not found" - install Node.js (which includes npm)
# "EACCES" permission error - use sudo or nvm (recommended)
# "E404" package not found - check spelling, run npm search first
# "EBADENGINE" invalid engine version - check Node version compatibility

# Clear cache and retry
npm cache clean --force
rm -rf node_modules package-lock.json
npm install

# Debug dependency issues
npm ls            # Show dependency tree
npm audit         # Check for known vulnerabilities

# Fix vulnerabilities
npm audit fix     # Automatic fixes where available
npm audit fix --force  # Force fixes
```