#!/bin/bash

echo "🔥 Starting HookHub Development Server"
echo "======================================"
echo ""
echo "✨ Features enabled:"
echo "   - Hot reload for templates (.heex)"
echo "   - Auto-recompile for Elixir code"
echo "   - Live browser refresh"
echo ""
echo "📍 Server will be available at:"
echo "   http://localhost:4000"
echo ""
echo "💡 Press Ctrl+C to stop"
echo ""

# Export environment variables
export DB_HOST=localhost
export DB_USER=hookhub
export DB_PASSWORD=hookhub_dev
export DB_NAME=hookhub_dev

# Start Phoenix server
mix phx.server
