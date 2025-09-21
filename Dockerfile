# Dockerfile for Flutter Web Build
# This creates a container that builds Flutter web and outputs static files
# Caddy will serve these files directly from a shared volume

# Build stage: Compile Flutter web app
FROM cirrusci/flutter:3.32.7 as build

# Set working directory
WORKDIR /app

# Copy pubspec files first for better layer caching
COPY pubspec.yaml pubspec.lock ./

# Enable web support and get dependencies
RUN flutter config --enable-web && \
    flutter pub get

# Copy source code
COPY . .

# Build web app for production
RUN flutter build web --release --no-tree-shake-icons

# Runtime stage: Copy built files to output volume
FROM alpine:3.18

# Install basic tools for debugging if needed
RUN apk add --no-cache curl

# Create directory for web files
RUN mkdir -p /var/www/html

# Copy built web files from build stage
COPY --from=build /app/build/web /var/www/html/

# Create a non-root user
RUN adduser -D -s /bin/sh webuser && \
    chown -R webuser:webuser /var/www/html

USER webuser

# Expose port (though Caddy will be the actual server)
EXPOSE 8080

# Health check endpoint (basic file existence check)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD test -f /var/www/html/index.html || exit 1

# Default command - just keep container running
# Caddy will serve files from the shared volume
CMD ["tail", "-f", "/dev/null"]