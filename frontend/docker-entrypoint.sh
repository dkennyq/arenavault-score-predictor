#!/bin/sh
set -e

echo "=== Nginx Railway Entrypoint ==="
echo "PORT environment variable: ${PORT:-NOT SET}"
echo "API_URL environment variable: ${API_URL:-NOT SET}"

# Set default PORT if not provided
export PORT=${PORT:-80}

# Set default API_URL if not provided
export API_URL=${API_URL:-http://localhost:5000/api}

echo "Using PORT: $PORT"
echo "Using API_URL: $API_URL"

# Generate nginx config from template
echo "Generating nginx config from template..."
envsubst '$PORT' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

# Generate env.js with runtime configuration
echo "Generating env.js with API_URL: $API_URL"
cat > /usr/share/nginx/html/env.js <<EOF
window.ENV = {
    API_URL: '$API_URL'
};
EOF

echo "Generated env.js:"
cat /usr/share/nginx/html/env.js

echo "Generated config:"
cat /etc/nginx/conf.d/default.conf

echo "Testing nginx config..."
nginx -t

echo "Starting nginx on port $PORT..."
exec nginx -g 'daemon off;'
