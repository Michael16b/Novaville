---
sidebar_position: 5
---

# Contributing to Novaville

This document describes best practices to contribute: PR workflow, conventions, tests and CI.

## Contribution process

1. Open an issue describing the change or bug.
2. Create a branch `feature/<name>` or `fix/<name>` from `main`.
3. Add unit tests for any business logic you change.
4. Open a Pull Request referencing the issue.

## Code conventions

- Backend: follow PEP8 and typing; use docstrings
- Frontend: follow `very_good_analysis` and BLoC structure

## CI / Tests

- PRs trigger GitHub Actions (build, tests).
- Run locally:

```bash
# Backend
docker compose exec backend pytest

# Frontend
flutter test
```

## Review and Merge

- PRs should have at least one approval and passing tests.
- Use atomic commits and clear messages.

Thanks for contributing!
