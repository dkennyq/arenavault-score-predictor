# Stage 1: Build static content
FROM nginx:alpine

# Copy the HTML file to nginx
COPY index.html /usr/share/nginx/html/

# Copy nginx configuration as template
COPY nginx.conf /etc/nginx/conf.d/default.conf.template

# Copy custom entrypoint
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Set default PORT for local development
ENV PORT=80

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
