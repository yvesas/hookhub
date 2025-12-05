#!/bin/bash

echo "🚀 HookHub Local Development Setup"
echo "===================================="
echo ""

# Check if Elixir is installed
if ! command -v elixir &> /dev/null; then
    echo "❌ Elixir not found. Please install Elixir 1.19+ first."
    echo "   Visit: https://elixir-lang.org/install.html"
    exit 1
fi

# Check if Mix is available
if ! command -v mix &> /dev/null; then
    echo "❌ Mix not found. Please install Elixir properly."
    exit 1
fi

echo "✅ Elixir $(elixir --version | grep Elixir | awk '{print $2}')"
echo ""

# Start only PostgreSQL in Docker
echo "📦 Starting PostgreSQL in Docker..."
docker compose up db -d

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
sleep 3

# Install dependencies
echo "📚 Installing dependencies..."
mix deps.get

# Setup database
echo "🗄️  Setting up database..."
export DB_HOST=localhost
mix ecto.create
mix ecto.migrate

# Run seeds
echo "🌱 Running seeds..."
mix run priv/repo/seeds.exs

echo ""
echo "✅ Setup complete!"
echo ""
echo "🔥 To start development server with hot reload:"
echo "   ./dev.sh"
echo ""
