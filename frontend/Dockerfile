# Stage 1: Build static content
FROM nginx:alpine

# Copy the HTML file to nginx
COPY index.html /usr/share/nginx/html/

# Copy nginx configuration as template
COPY nginx.conf /etc/nginx/conf.d/default.conf.template

# Copy entrypoint script and fix line endings
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN sed -i 's/\r$//' /docker-entrypoint.sh && \
    chmod +x /docker-entrypoint.sh

# Set default environment variables for local development
ENV PORT=80
ENV API_URL=http://localhost:5000/api

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
