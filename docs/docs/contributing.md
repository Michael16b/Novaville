---
sidebar_position: 5
---

# Contribuer au projet Novaville

Ce document décrit les bonnes pratiques pour contribuer au code : ouverture de PR, conventions, tests et CI.

## Processus de contribution

1. Ouvrir une issue décrivant le changement ou le bug.
2. Créer une branche `feature/<nom>` ou `fix/<nom>` depuis `main`.
3. Fournir des tests unitaires pour toute logique métier ajoutée ou modifiée.
4. Soumettre une Pull Request décrite et liée à l'issue.

## Conventions de code

- Backend : respectez PEP8 et les types, utilisez des docstrings
- Frontend : suivez `very_good_analysis` et la structure BLoC

## CI / Tests

- Les PR déclenchent les workflows GitHub Actions (build, tests).
- Exécutez localement :

```bash
# Backend
docker compose exec backend pytest

# Frontend
flutter test
```

## Revue et Merge

- Les PR doivent avoir au moins une approbation et des tests verts.
- Utiliser des commits atomiques et messages clairs.

Merci de contribuer !
