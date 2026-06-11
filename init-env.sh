#!/bin/bash
# init-env.sh - Initialize .env file for development if it doesn't exist

set -e

ENV_FILE=".env"

if [ -f "$ENV_FILE" ]; then
    echo "✓ $ENV_FILE already exists"
    exit 0
fi

echo "📝 Creating $ENV_FILE from .env.example..."

# Copy .env.example to .env
if [ ! -f ".env.example" ]; then
    echo "❌ Error: .env.example not found"
    exit 1
fi

cp .env.example "$ENV_FILE"

echo "✓ $ENV_FILE created successfully"
echo ""
echo "⚠️  IMPORTANT: Edit $ENV_FILE and set your values:"
echo "   - DB_PASSWORD: PostgreSQL password (required)"
echo "   - DJANGO_SECRET_KEY: Random secret (at least 50 chars)"
echo "   - JWT_SIGNING_KEY: Random secret (at least 50 chars)"
echo "   - DJANGO_SUPERUSER_PASSWORD: Admin password"
echo ""
echo "Then run: docker compose up -d --build"
