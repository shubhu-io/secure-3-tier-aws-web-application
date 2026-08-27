# JavaScript HTTP Server Example

A minimal HTTP server implemented using Node.js built-in `http` module.

## Structure

```
javascript/
├── Dockerfile
├── package.json
├── src/index.js    # HTTP server source
├── test/index.test.js  # Unit tests
└── .dockerignore
```

## Commands

```bash
# Install dependencies
npm install

# Run tests
npm test

# Start the server
npm start
```

## Docker

```bash
# Build the image
docker build -t javascript-http-server .

# Run the container
docker run -p 3000:3000 javascript-http-server
```

The server runs on port 3000 and provides the following endpoints:

- `GET /` - Welcome message
- `GET /health` - Health check
- `GET /items` - List all items
- `POST /items` - Create a new item (requires `name` in JSON body)
- `DELETE /items` - Clear all items