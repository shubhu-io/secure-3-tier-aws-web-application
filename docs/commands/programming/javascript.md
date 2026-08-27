# JavaScript

Reference commands for JavaScript development. This project uses Node.js (React + Node/Express).

## Version Check

```bash
node --version
npm --version
```

## Installation

```bash
# Install dependencies
npm install

# Install globally (if needed)
npm install -g <package>
```

## Hello World

```bash
# Create a simple script
echo "console.log('Hello, World!');" > hello.js
node hello.js
```

## Dependency/Package Installation

```bash
npm install <package>           # Install a package and save to package.json
npm install --save-dev <pkg>    # Install as dev dependency
npm uninstall <package>         # Remove a package
npm update                      # Update all packages
```

## Build

```bash
# Using Vite (this project's frontend build tool)
npm run build

# Alternative: direct Vite
npx vite build
```

## Run

```bash
# Development server (Vite + React)
npm run dev

# Start production server
npm start

# Node.js script
node app.js
```

## Test

```bash
# Using Jest (common JS test framework)
npm test
npx jest

# Alternative test runners
npx mocha
npx tap
```

## Lint

```bash
# Using ESLint (standard in JS ecosystem)
npm run lint
npx eslint .

# Using Prettier
npm run format
npx prettier --write .
```

## Format

```bash
npx prettier --write .
npm run format
```

## Compile

JavaScript is interpreted, not compiled. Use transpilers if needed:

```bash
# Babel (for ES6+ -> ES5 transpilation)
npx babel src --out-dir lib
# Or via Vite (this project)
npm run build
```

## Package

```bash
# Create a distributable package
npm pack

# Or use the project's build output
ls -la dist/  # frontend build output
```

## Clean

```bash
# Remove node_modules and lock file
rm -rf node_modules package-lock.json
rm -rf dist  # frontend build output

# Reinstall from scratch
npm install
```

## Production Build

```bash
npm run build   # Vite production build
# Or:
npx vite build --mode production
```

## Troubleshooting

```bash
# Clear npm cache and reinstall
npm cache clean --force
rm -rf node_modules package-lock.json
npm install

# Debug dependency issues
npm ls        # List dependency tree
npm audit     # Check for known vulnerabilities
```