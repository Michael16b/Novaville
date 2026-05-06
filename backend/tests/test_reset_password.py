#!/usr/bin/env python
"""Test script for reset_password endpoint."""
import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
sys.path.insert(0, '/app')
django.setup()

from core.db.models import User
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.test import APIClient
import json

# Create users
admin = User.objects.create_user(
    username='admin_reset_test',
    email='admin_reset@test.com',
    password='AdminPass123!',
    is_staff=True,
    is_superuser=True
)
target = User.objects.create_user(
    username='target_reset_test',
    email='target_reset@test.com',
    password='TargetPass123!'
)

print(f'Admin ID: {admin.id}')
print(f'Target ID: {target.id}')

# Test with APIClient
client = APIClient()
client.force_authenticate(user=admin)

url = f'/api/v1/users/{target.id}/reset_password/'
print(f'\nTesting: POST {url}')
response = client.post(url)
print(f'Status Code: {response.status_code}')
if hasattr(response, 'data'):
    print(f'Response Data: {json.dumps(response.data, indent=2)}')
else:
    print(f'Response Content: {response.content}')
