#!/bin/bash

# Heroku startup script for Expense Sage
set -e

echo "🚀 Starting Expense Sage on Heroku..."

# Use Heroku's PORT environment variable
export PORT=${PORT:-80}

echo "📝 Using PORT: $PORT"

# Replace $PORT in nginx config
envsubst '$PORT' < /etc/nginx/conf.d/default.conf > /tmp/default.conf
mv /tmp/default.conf /etc/nginx/conf.d/default.conf

# Initialize database if it doesn't exist
if [ ! -f /app/data/expense_sage.db ]; then
    echo "🗄️ Initializing database..."
    /app/init-db.sh
fi

echo "🌐 Starting Nginx on port $PORT..."

# Start nginx in foreground
nginx -g "daemon off;"
