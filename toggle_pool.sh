#!/bin/sh
# Usage: ./toggle_pool.sh blue|green
if [ $# -ne 1 ]; then
  echo "Usage: $0 blue|green"
  exit 1
fi
TARGET="$1"
if [ ! -f .env ]; then
  echo ".env missing. Copy .env.example -> .env and edit."
  exit 2
fi

# update or append ACTIVE_POOL in .env
if grep -q '^ACTIVE_POOL=' .env; then
  sed -i.bak -E "s/^ACTIVE_POOL=.*/ACTIVE_POOL=${TARGET}/" .env
else
  echo "ACTIVE_POOL=${TARGET}" >> .env
fi

# Recreate nginx only so entrypoint picks up new ACTIVE_POOL and regenerates config
docker compose up -d --no-deps --force-recreate nginx

# Wait, then reload config inside container
sleep 1
docker compose exec nginx nginx -t && docker compose exec nginx nginx -s reload

echo "Switched ACTIVE_POOL to ${TARGET} and reloaded nginx"
