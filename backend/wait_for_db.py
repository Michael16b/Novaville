#!/usr/bin/env python
"""
wait_for_db.py
Wait for database to be available before proceeding.
Retries connection for a configurable time period.

This script is called by the Dockerfile CMD before running migrations
to ensure the database is ready to accept connections. This prevents
connection refused errors during Azure deployments where the backend
container may start before PostgreSQL is fully initialized.

Usage:
    python wait_for_db.py

Environment Variables:
    DB_HOST: Database host (default: localhost)
    DB_PORT: Database port (default: 5432)
    DB_NAME: Database name (default: novaville)
    DB_USER: Database user (default: postgres)
    DB_PASSWORD: Database password (default: ton_password_securise)
    DB_WAIT_MAX_RETRIES: Maximum retry attempts (default: 30)
    DB_WAIT_RETRY_INTERVAL: Seconds between retries (default: 2)
"""
import os
import sys
import time
import psycopg2
from psycopg2 import OperationalError

def wait_for_db(max_retries=30, retry_interval=2):
    """
    Wait for database to become available.
    
    Args:
        max_retries: Maximum number of connection attempts (default: 30)
        retry_interval: Seconds to wait between retries (default: 2)
    
    Returns:
        bool: True if connection successful, False otherwise
    """
    db_config = {
        'dbname': os.environ.get('DB_NAME', 'novaville'),
        'user': os.environ.get('DB_USER', 'postgres'),
        'password': os.environ.get('DB_PASSWORD'),  # Required - must be set via environment
        'host': os.environ.get('DB_HOST', 'localhost'),
        'port': os.environ.get('DB_PORT', '5432'),
    }
    
    # Validate required environment variables
    if not db_config['password']:
        print("[wait_for_db] ERROR: DB_PASSWORD environment variable is required")
        return False
    
    print(f"[wait_for_db] Waiting for database at {db_config['host']}:{db_config['port']}...")
    print(f"[wait_for_db] Database: {db_config['dbname']}, User: {db_config['user']}")
    
    for attempt in range(1, max_retries + 1):
        try:
            print(f"[wait_for_db] Attempt {attempt}/{max_retries}...")
            conn = psycopg2.connect(**db_config)
            conn.close()
            print("[wait_for_db] Database is ready!")
            return True
        except OperationalError as e:
            if attempt == max_retries:
                print(f"[wait_for_db] ERROR: Failed to connect after {max_retries} attempts")
                print(f"[wait_for_db] Last error: {e}")
                return False
            print(f"[wait_for_db] Database not ready yet, retrying in {retry_interval}s...")
            time.sleep(retry_interval)
    
    return False

if __name__ == '__main__':
    # Allow customization via environment variables
    max_retries = int(os.environ.get('DB_WAIT_MAX_RETRIES', 30))
    retry_interval = int(os.environ.get('DB_WAIT_RETRY_INTERVAL', 2))
    
    success = wait_for_db(max_retries=max_retries, retry_interval=retry_interval)
    sys.exit(0 if success else 1)
