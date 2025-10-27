# Node App (Blue/Green test app)

This Node.js app implements the endpoints required for the Stage 2 Blue/Green task:
- `GET /version` (returns JSON + headers `X-App-Pool` and `X-Release-Id`)
- `POST /chaos/start?mode=error|timeout`
- `POST /chaos/stop`
- `GET /healthz`

## Files
- `server.js` – Express app
- `package.json`
- `Dockerfile`
- `.dockerignore`

## Local development / quick test

1. Build images locally:
   ```bash
   # from project root where node-app/ exists
   docker build -t node-app-blue:latest ./node-app
   docker tag node-app-blue:latest node-app-green:latest

