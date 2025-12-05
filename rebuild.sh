#!/bin/bash

echo "🔄 Rebuilding HookHub Docker containers..."
echo ""

# Stop and remove containers
echo "📦 Stopping containers..."
docker compose down

# Rebuild without cache
echo "🏗️  Building fresh image (no cache)..."
docker compose build --no-cache app

# Start containers
echo "🚀 Starting containers..."
docker compose up -d

# Wait for app to be ready
echo "⏳ Waiting for application to start..."
sleep 8

# Check if containers are running
echo ""
echo "✅ Container status:"
docker compose ps

echo ""
echo "🎉 Rebuild complete!"
echo ""
echo "📍 Access your application at:"
echo "   - Dashboard: http://localhost:4000/dashboard"
echo "   - API Keys:  http://localhost:4000/dashboard/api-keys"
echo ""
