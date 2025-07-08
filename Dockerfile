# Multi-stage build for Flutter Web Production
FROM ubuntu:22.04 AS build

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    wget \
    unzip \
    xz-utils \
    zip \
    libgconf-2-4 \
    gdb \
    libstdc++6 \
    libglu1-mesa \
    fonts-droid-fallback \
    lib32stdc++6 \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
ENV FLUTTER_HOME="/opt/flutter"
ENV PATH="$FLUTTER_HOME/bin:$PATH"

RUN git clone https://github.com/flutter/flutter.git $FLUTTER_HOME \
    && cd $FLUTTER_HOME \
    && git checkout stable \
    && flutter doctor

# Enable web support
RUN flutter config --enable-web

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy source code
COPY . .

# Build for web production
RUN flutter build web --release --web-renderer html

# Production stage with Nginx
FROM nginx:alpine AS production

# Install additional tools
RUN apk add --no-cache \
    sqlite \
    curl \
    bash

# Copy custom nginx configuration
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/default.conf /etc/nginx/conf.d/default.conf

# Copy built Flutter web app
COPY --from=build /app/build/web /usr/share/nginx/html

# Create directory for SQLite database
RUN mkdir -p /app/data && \
    chown -R nginx:nginx /app/data

# Copy database initialization script
COPY docker/init-db.sh /docker-entrypoint-initdb.d/

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
