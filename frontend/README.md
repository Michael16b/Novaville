# Frontend UniCity

Application Flutter (Web, iOS, Android) de la plateforme citoyenne Novaville.

## Lancer en local (Web)

```bash
flutter pub get
flutter run -d chrome --web-port 3000
```

## PWA (Progressive Web App)

Le projet est configuré en PWA via Flutter Web:

- manifeste: `web/manifest.json`
- métadonnées HTML: `web/index.html`
- service worker: généré automatiquement au build Flutter Web
- icônes installables: `web/icons/`

### Build PWA recommandé

```bash
flutter build web --release --pwa-strategy=offline-first
```

Le dossier généré est `build/web`.

### Tester l'installation PWA

1. Servir `build/web` derrière HTTPS (ou en `localhost` en local).
2. Ouvrir l'application dans Chrome/Edge.
3. Vérifier l'option d'installation (« Installer l'application »).

### Notes importantes

- Le cache PWA est géré par le service worker Flutter.
- Après un nouveau déploiement, un rechargement complet peut être nécessaire pour récupérer la nouvelle version.

### Régénérer les icônes web (branding)

Les icônes PWA sont générées depuis `assets/images/logo.png`.

```bash
dart run flutter_launcher_icons
```

### Vérification qualité PWA (recommandé)

- Ouvrir DevTools > Application pour vérifier `manifest.json` et `service worker`.
- Exécuter un audit Lighthouse (catégorie PWA) en build release.
