#!/bin/bash

# Build script for Propofol Dreams Flutter Web App
# This script builds and deploys the Flutter web app using Docker Compose

set -e

echo "🚀 Building Propofol Dreams Flutter Web App..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
    print_error "Docker Compose is not available. Please install Docker Compose."
    exit 1
fi

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Change to project directory
cd "$PROJECT_DIR"

print_status "Current directory: $PROJECT_DIR"

# Clean up any existing containers
print_status "Cleaning up existing containers..."
docker-compose down --remove-orphans 2>/dev/null || true

# Build and start the services
print_status "Building Flutter web app container..."
docker-compose build --no-cache

print_status "Starting services..."
docker-compose up -d

# Wait for the web app to be ready
print_status "Waiting for Flutter web app to be ready..."
max_attempts=30
attempt=0

while [ $attempt -lt $max_attempts ]; do
    if docker-compose exec -T propofol-dreams-web test -f /var/www/html/index.html >/dev/null 2>&1; then
        print_success "Flutter web app is ready!"
        break
    fi

    attempt=$((attempt + 1))
    echo -n "."
    sleep 2
done

if [ $attempt -eq $max_attempts ]; then
    print_error "Flutter web app failed to start within expected time."
    print_status "Container logs:"
    docker-compose logs propofol-dreams-web
    exit 1
fi

# Show service status
print_status "Service status:"
docker-compose ps

# Show helpful information
print_success "✅ Propofol Dreams Flutter Web App is now running!"
echo ""
print_status "📁 Web files are available in the 'web-files' Docker volume"
print_status "🌐 Test URL: http://localhost (if using the example Caddy service)"
print_status "📋 To view logs: docker-compose logs -f"
print_status "🛑 To stop: docker-compose down"
echo ""
print_warning "📝 Note: You need to configure your own Caddy service to serve the files from the 'web-files' volume"
print_warning "📝 The web files are located at: /srv in the Caddy container (via shared volume)"

# Optional: Show example Caddyfile
cat << 'EOF'

📄 Example Caddyfile configuration:
```
your-domain.com {
    root * /srv
    file_server

    # Enable compression
    encode gzip zstd

    # Security headers
    header {
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        Referrer-Policy strict-origin-when-cross-origin
    }

    # Handle Flutter routing
    try_files {path} /index.html
}
```
EOF