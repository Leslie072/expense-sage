#!/bin/bash

# Quick production deployment script for Expense Sage
echo "🚀 Quick Deploy - Expense Sage to Production"

# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
echo "📦 Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
echo "📦 Installing Docker Compose..."
sudo apt install docker-compose-plugin -y

# Clone repository (you'll need to replace with your repo URL)
echo "📥 Cloning repository..."
git clone https://github.com/yourusername/expense_sage.git
cd expense_sage

# Set up environment
echo "⚙️ Setting up environment..."
cp .env.production .env

# Create directories
mkdir -p data docker/backup docker/ssl logs

# Generate SSL certificates (self-signed for now)
echo "🔒 Generating SSL certificates..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout docker/ssl/private.key \
    -out docker/ssl/cert.pem \
    -subj "/C=US/ST=State/L=City/O=ExpenseSage/CN=localhost"

chmod 600 docker/ssl/private.key
chmod 644 docker/ssl/cert.pem

# Build and deploy
echo "🏗️ Building and deploying..."
docker-compose build --no-cache
docker-compose up -d

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 60

# Health check
echo "🏥 Running health check..."
if curl -f http://localhost/health; then
    echo "✅ Deployment successful!"
    echo "🌐 Your app is running at: http://$(curl -s ifconfig.me)"
    echo "🔧 Admin panel: http://$(curl -s ifconfig.me)/admin"
else
    echo "❌ Health check failed"
    docker-compose logs
fi

echo "🎉 Deployment complete!"
