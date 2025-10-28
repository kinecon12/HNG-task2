#!/bin/sh
# scripts/reload-nginx.sh

echo "Switching to ${ACTIVE_POOL}..."
docker exec nginx envsubst '$ACTIVE_POOL' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf
docker exec nginx nginx -s reload
export ACTIVE_POOL=green
docker compose up -d --force-recreate nginx

