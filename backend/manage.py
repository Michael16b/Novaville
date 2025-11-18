#!/usr/bin/env python
"""Django's command-line utility for administrative tasks.

This file was added to allow running Django management commands. It assumes
the project settings module is `config.settings` (adjust if necessary).
"""
import os
import sys


def main():
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and"
            " available on your PYTHONPATH environment variable? Did you"
            " forget to activate a virtual environment?"
        ) from exc
    execute_from_command_line(sys.argv)


if __name__ == '__main__':
    main()
