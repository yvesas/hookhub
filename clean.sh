#!/bin/bash

echo "🧹 Cleaning HookHub Development Environment"
echo "==========================================="
echo ""

# Stop Phoenix server if running
echo "🛑 Stopping any running Phoenix servers..."
pkill -f "mix phx.server" 2>/dev/null || true

# Stop Docker containers
echo "📦 Stopping Docker containers..."
docker compose down

# Clean build artifacts
echo "🗑️  Cleaning build artifacts..."
rm -rf _build
rm -rf deps
rm -rf .elixir_ls

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "💡 To start fresh:"
echo "   ./setup_local.sh  # Setup local dev"
echo "   ./rebuild.sh      # Rebuild Docker"
echo ""
