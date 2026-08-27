# TypeScript

Reference commands for TypeScript development.

## Version Check

```bash
tsc --version
```

## Installation

```bash
# Install TypeScript globally
npm install -g typescript

# Or as a project dependency
npm install --save-dev typescript
```

## Hello World

```bash
# Create a simple TypeScript file
echo 'const msg: string = "Hello, World!"; console.log(msg);' > hello.ts
tsc hello.ts && node hello.js
```

## Installation & Setup

```bash
# Initialize TypeScript config
tsc --init

# Or with this project's config
npx tsc --project tsconfig.json
```

## Dependency/Package Installation

Same as JavaScript - use npm:

```bash
npm install <package>
npm install --save-dev <pkg>
```

## Build

```bash
# Compile TypeScript to JavaScript
npx tsc          # Using tsconfig.json
npx tsc --project tsconfig.json

# With this project (Vite + TS support)
npm run build     # Handles TS compilation internally
```

## Run

```bash
# After compilation, run the JS output
node dist/index.js   # Assuming tsconfig outputs to dist/

# Or use ts-node for direct execution
npx ts-node app.ts
```

## Test

```bash
# Jest with TypeScript support
npm test          # As defined in package.json
npx jest

# ts-jest for TypeScript test files
npx jest --tsconfigPath tsconfig.json
```

## Lint

```bash
# ESLint with TypeScript
npm run lint      # As defined in package.json
npx eslint --ext .ts,.tsx .

# Or use eslint-plugin-typescript
```

## Format

```bash
npx prettier --write .
npm run format
```

## Clean

```bash
# Remove compiled output
rm -rf dist
rm -rf .tsbuildinfo

# Recompile
npx tsc
```

## Production Build

```bash
npm run build     # Vite handles TS compilation + production minification
```

## Troubleshooting

```bash
# Check for type errors
npx tsc --noEmit

# Watch mode
npx tsc --watch
```