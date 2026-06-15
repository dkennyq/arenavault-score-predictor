# Stage 1: Build static content
FROM nginx:alpine

# Copy the HTML file to nginx
COPY index.html /usr/share/nginx/html/

# Copy nginx configuration as template
COPY nginx.conf /etc/nginx/conf.d/default.conf.template

# Create entrypoint script directly in Dockerfile (avoids Windows line ending issues)
RUN echo '#!/bin/sh' > /docker-entrypoint.sh && \
    echo 'set -e' >> /docker-entrypoint.sh && \
    echo 'echo "=== Nginx Railway Entrypoint ==="' >> /docker-entrypoint.sh && \
    echo 'echo "PORT environment variable: ${PORT:-NOT SET}"' >> /docker-entrypoint.sh && \
    echo 'export PORT=${PORT:-80}' >> /docker-entrypoint.sh && \
    echo 'echo "Using PORT: $PORT"' >> /docker-entrypoint.sh && \
    echo 'echo "Generating nginx config from template..."' >> /docker-entrypoint.sh && \
    echo 'envsubst '"'"'$PORT'"'"' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf' >> /docker-entrypoint.sh && \
    echo 'echo "Generated config:"' >> /docker-entrypoint.sh && \
    echo 'cat /etc/nginx/conf.d/default.conf' >> /docker-entrypoint.sh && \
    echo 'echo "Testing nginx config..."' >> /docker-entrypoint.sh && \
    echo 'nginx -t' >> /docker-entrypoint.sh && \
    echo 'echo "Starting nginx on port $PORT..."' >> /docker-entrypoint.sh && \
    echo 'exec nginx -g '"'"'daemon off;'"'"'' >> /docker-entrypoint.sh && \
    chmod +x /docker-entrypoint.sh

# Set default PORT for local development
ENV PORT=80

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
