#!/bin/sh
set -e

echo "=== Nginx Railway Entrypoint ==="
echo "PORT environment variable: ${PORT:-NOT SET}"

# Set default PORT if not provided
export PORT=${PORT:-80}

echo "Using PORT: $PORT"

# Generate nginx config from template
echo "Generating nginx config from template..."
envsubst '$PORT' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

echo "Generated config:"
cat /etc/nginx/conf.d/default.conf

echo "Testing nginx config..."
nginx -t

echo "Starting nginx on port $PORT..."
exec nginx -g 'daemon off;'
