# Railway Dockerfile for Expense Sage Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS build

# Set working directory
WORKDIR /app

# Copy pubspec files for dependency caching
COPY pubspec.yaml pubspec.lock ./

# Install dependencies
RUN flutter pub get

# Copy all source code
COPY . .

# Build Flutter web app for production
RUN flutter build web --release

# Production stage with Nginx
FROM nginx:alpine

# Install SQLite for database
RUN apk add --no-cache sqlite curl

# Create app directory and set permissions
RUN mkdir -p /app/data && chmod 755 /app/data

# Copy built Flutter web files
COPY --from=build /app/build/web /usr/share/nginx/html

# Create Railway-compatible nginx configuration
RUN echo 'server {' > /etc/nginx/conf.d/default.conf && \
    echo '    listen $PORT;' >> /etc/nginx/conf.d/default.conf && \
    echo '    server_name _;' >> /etc/nginx/conf.d/default.conf && \
    echo '    root /usr/share/nginx/html;' >> /etc/nginx/conf.d/default.conf && \
    echo '    index index.html;' >> /etc/nginx/conf.d/default.conf && \
    echo '' >> /etc/nginx/conf.d/default.conf && \
    echo '    # Flutter web routing' >> /etc/nginx/conf.d/default.conf && \
    echo '    location / {' >> /etc/nginx/conf.d/default.conf && \
    echo '        try_files $uri $uri/ /index.html;' >> /etc/nginx/conf.d/default.conf && \
    echo '    }' >> /etc/nginx/conf.d/default.conf && \
    echo '' >> /etc/nginx/conf.d/default.conf && \
    echo '    # Health check' >> /etc/nginx/conf.d/default.conf && \
    echo '    location /health {' >> /etc/nginx/conf.d/default.conf && \
    echo '        return 200 "healthy";' >> /etc/nginx/conf.d/default.conf && \
    echo '        add_header Content-Type text/plain;' >> /etc/nginx/conf.d/default.conf && \
    echo '    }' >> /etc/nginx/conf.d/default.conf && \
    echo '' >> /etc/nginx/conf.d/default.conf && \
    echo '    # Cache static assets' >> /etc/nginx/conf.d/default.conf && \
    echo '    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {' >> /etc/nginx/conf.d/default.conf && \
    echo '        expires 1y;' >> /etc/nginx/conf.d/default.conf && \
    echo '        add_header Cache-Control "public, immutable";' >> /etc/nginx/conf.d/default.conf && \
    echo '    }' >> /etc/nginx/conf.d/default.conf && \
    echo '}' >> /etc/nginx/conf.d/default.conf

# Create database initialization script
RUN echo '#!/bin/sh' > /app/init-db.sh && \
    echo 'DB_PATH="/app/data/expense_sage.db"' >> /app/init-db.sh && \
    echo 'if [ ! -f "$DB_PATH" ]; then' >> /app/init-db.sh && \
    echo '  echo "Initializing database..."' >> /app/init-db.sh && \
    echo '  sqlite3 "$DB_PATH" "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, email TEXT UNIQUE, username TEXT, password_hash TEXT, created_at TEXT, updated_at TEXT, is_active INTEGER DEFAULT 1);"' >> /app/init-db.sh && \
    echo '  sqlite3 "$DB_PATH" "CREATE TABLE IF NOT EXISTS admins (id INTEGER PRIMARY KEY, email TEXT UNIQUE, username TEXT, password_hash TEXT, role INTEGER, created_at TEXT, updated_at TEXT, is_active INTEGER DEFAULT 1);"' >> /app/init-db.sh && \
    echo '  sqlite3 "$DB_PATH" "CREATE TABLE IF NOT EXISTS accounts (id INTEGER PRIMARY KEY, name TEXT, user_id INTEGER);"' >> /app/init-db.sh && \
    echo '  sqlite3 "$DB_PATH" "CREATE TABLE IF NOT EXISTS categories (id INTEGER PRIMARY KEY, name TEXT, user_id INTEGER);"' >> /app/init-db.sh && \
    echo '  sqlite3 "$DB_PATH" "CREATE TABLE IF NOT EXISTS payments (id INTEGER PRIMARY KEY, amount REAL, description TEXT, date TEXT, user_id INTEGER);"' >> /app/init-db.sh && \
    echo '  echo "Database initialized successfully"' >> /app/init-db.sh && \
    echo 'fi' >> /app/init-db.sh && \
    chmod +x /app/init-db.sh

# Create startup script for Railway
RUN echo '#!/bin/sh' > /start.sh && \
    echo 'echo "Starting Expense Sage on Railway..."' >> /start.sh && \
    echo 'export PORT=${PORT:-80}' >> /start.sh && \
    echo 'echo "Using PORT: $PORT"' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Initialize database' >> /start.sh && \
    echo '/app/init-db.sh' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Replace PORT in nginx config' >> /start.sh && \
    echo 'envsubst "\$PORT" < /etc/nginx/conf.d/default.conf > /tmp/default.conf' >> /start.sh && \
    echo 'mv /tmp/default.conf /etc/nginx/conf.d/default.conf' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start nginx' >> /start.sh && \
    echo 'echo "Starting nginx on port $PORT..."' >> /start.sh && \
    echo 'nginx -g "daemon off;"' >> /start.sh && \
    chmod +x /start.sh

# Expose port (Railway will set PORT env var)
EXPOSE $PORT

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:$PORT/health || exit 1

# Start the application
CMD ["/start.sh"]
