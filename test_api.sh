#!/bin/bash

# HookHub Test Script
# This script tests the webhook ingestion and API endpoints

set -e

echo "🧪 HookHub Test Suite"
echo "===================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Base URL
BASE_URL="http://localhost:4000"

# Function to print test results
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
    else
        echo -e "${RED}✗ $2${NC}"
        exit 1
    fi
}

# Wait for server to be ready
echo "⏳ Waiting for server to be ready..."
for i in {1..30}; do
    if curl -s "$BASE_URL" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Server is ready${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}✗ Server failed to start${NC}"
        exit 1
    fi
    sleep 1
done

echo ""
echo "📝 Running tests..."
echo ""

# Test 1: Home page
echo "Test 1: Home page accessibility"
curl -s -o /dev/null -w "%{http_code}" "$BASE_URL" | grep -q "200"
print_result $? "Home page loads"

# Test 2: Dashboard page
echo "Test 2: Dashboard page"
curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/dashboard" | grep -q "200"
print_result $? "Dashboard page loads"

# Test 3: API Keys page
echo "Test 3: API Keys management page"
curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/dashboard/api-keys" | grep -q "200"
print_result $? "API Keys page loads"

# Test 4: List events API (should work without auth for GET)
echo "Test 4: List events API"
curl -s "$BASE_URL/api/events" | grep -q "data"
print_result $? "Events API returns data"

# Test 5: List API keys
echo "Test 5: List API keys"
curl -s "$BASE_URL/api/keys" | grep -q "data"
print_result $? "API Keys API returns data"

echo ""
echo -e "${GREEN}✅ All basic tests passed!${NC}"
echo ""
echo "📋 Next steps:"
echo "1. Run seeds to create providers and API keys:"
echo "   docker compose exec app mix run priv/repo/seeds.exs"
echo ""
echo "2. Test webhook ingestion with the generated API keys"
echo "   See API_EXAMPLES.md for curl examples"
echo ""
