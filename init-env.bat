@echo off
REM init-env.bat - Initialize .env file for development if it doesn't exist

setlocal enabledelayedexpansion

set "ENV_FILE=.env"

if exist "%ENV_FILE%" (
    echo.✓ %ENV_FILE% already exists
    exit /b 0
)

echo.📝 Creating %ENV_FILE% from .env.example...

if not exist ".env.example" (
    echo.❌ Error: .env.example not found
    exit /b 1
)

copy .env.example "%ENV_FILE%" >nul

echo.✓ %ENV_FILE% created successfully
echo.
echo.⚠️  IMPORTANT: Edit %ENV_FILE% and set your values:
echo.   - DB_PASSWORD: PostgreSQL password (required)
echo.   - DJANGO_SECRET_KEY: Random secret (at least 50 chars)
echo.   - JWT_SIGNING_KEY: Random secret (at least 50 chars)
echo.   - DJANGO_SUPERUSER_PASSWORD: Admin password
echo.
echo.Then run: docker compose up -d --build
