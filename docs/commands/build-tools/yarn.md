# Yarn

Reference commands for Yarn (alternative npm client). This project uses npm, but Yarn is a popular alternative with different features.

## Installation

```bash
# macOS
brew install yarn

# npm install (recommended):
npm install --global yarn

# Or using npx
npx yarn --version

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y yarn

# Verify
yarn --version
```

## Version Check

```bash
yarn --version
```

## Dependency/Package Installation

Yarn is compatible with npm packages but has different commands:

```bash
# Install all dependencies (read from package.json)
yarn install

# Or: yarn

# Add a new dependency (adds to package.json and yarn.lock)
yarn add <package>

# Add specific version
yarn add <package>@<version>

# Add as dev dependency
yarn add --dev <package>

# Remove a dependency
yarn remove <package>

# Upgrade all dependencies
yarn upgrade

# Upgrade a specific package
yarn upgrade <package>

# Add workspace (for monorepos)
yarn workspaces add <package>

# This project uses npm, but Yarn commands are compatible
# package.json is shared, but lock files differ (yarn.lock vs package-lock.json)
```

## Build

Same as npm for this project:

```bash
# This project uses npm scripts, but Yarn is compatible:
yarn build        # Same as npm run build

# Or direct Vite
npx vite build
```

## Run

```bash
# This project uses npm scripts:
yarn dev          # Same as npm run dev

# Or:
yarn start        # Same as npm start
```

## Test

```bash
# This project uses npm/test, but Yarn is compatible:
yarn test         # Same as npm test

# Or:
yarn jest         # Run Jest directly
```

## Lint

```bash
# This project uses npm/lint, but Yarn is compatible:
yarn lint         # Same as npm run lint

# Or:
yarn eslint       # Run ESLint directly
```

## Format

```bash
# This project uses npm/format, but Yarn is compatible:
yarn format       # Same as npm run format

# Or:
npx prettier --write .
```

## Clean

```bash
# Same as npm (project uses node_modules + package-lock.json)
yarn remove       # Remove a dependency

# Or reinstall
yarn install      # Reinstall all dependencies

# yarn remove <package>   # Remove from dependencies
# yarn install            # Reinstall
```

## Troubleshooting

```bash
# Common issues
# "yarn: command not found" - install Yarn (brew install yarn or npm install -g yarn)
# "lockfile mismatch" - yarn.lock vs package-lock.json conflict
# Delete the conflicting lock file and run: yarn install or npm install

# Switch between package managers (not recommended for same project):
# rm package-lock.json  # For npm
# rm yarn.lock          # For Yarn
# Then use the other manager

# Clear cache
yarn cache clean    # Clear Yarn's internal cache

# Debug dependency issues
yarn why <package>  # Why is this package installed?
yarn resolutions    # Check version resolutions
```