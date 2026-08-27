# Node.js

Reference commands for Node.js development. This project uses Node.js (React frontend + Node/Express backend).

## Version Check

```bash
node --version
npm --version
npx --version
```

## Installation

```bash
# Install Node.js (recommended: use nvm)
# macOS: brew install node
# Ubuntu: curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && apt-get install -y nodejs
# Windows: Download installer from nodejs.org

# Or using nvm (recommended)
nvm install 20
nvm use 20
nvm ls
```

## Hello World

```bash
# Create and run a simple script
echo "console.log('Hello, World!');" > hello.js
node hello.js
```

## Dependency/Package Installation

```bash
# Install a package and save to package.json
npm install <package>

# Install as dev dependency
npm install --save-dev <package>

# Install globally
npm install -g <package>

# Update all packages
npm update

# Audit for vulnerabilities
npm audit

# Fix automatic fixes (where possible)
npm audit fix
```

## Build

```bash
# This project's frontend (Vite + React)
npm run build   # Creates dist/ with compiled assets

# Direct Vite build
npx vite build

# Node.js project build (if applicable)
# Most Node projects don't have a "build" step beyond npm install
```

## Run

```bash
# Development mode
npm run dev     # Vite dev server + nodemon for backend (as per package.json scripts)

# Production mode
npm start       # Starts production server (as defined in package.json scripts)

# Direct execution
node app.js     # Run a Node.js script
node server.js

# With PM2 (process manager)
pm2 start app.js
pm2 list
pm2 logs
```

## Test

```bash
# This project's backend tests
npm test          # As defined in backend package.json

# Using Jest (common in Node.js projects)
npx jest

# Run specific test file
npx jest --testPathPattern="auth.test"

# Coverage report
npm test -- --coverage
npx jest --coverage
```

## Lint

```bash
# ESLint (standard in Node.js ecosystem)
npm run lint      # As defined in package.json

# Direct ESLint
npx eslint .

# With autofix
npx eslint --fix .

# Prettier formatting
npm run format
npx prettier --write .
```

## Format

```bash
npx prettier --write .
npm run format
```

## Troubleshooting

```bash
# Clear Node.js cache
node --del-cache

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install

# Check Node version compatibility
nvm use 20      # Switch Node version

# Common errors
# "EACCESS: permission denied" - use sudo or nvm
# "Cannot find module" - run npm install
# "ENOENT: no such file or directory" - check file paths
```