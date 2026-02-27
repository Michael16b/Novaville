# Frontend UniCity

Flutter application (Web, iOS, Android) for the Novaville citizen platform.

## Run locally (Web)

```bash
flutter pub get
flutter run -d chrome --web-port 3000
```

## PWA (Progressive Web App)

The project is configured as a PWA through Flutter Web:

- manifest: `web/manifest.json`
- HTML metadata: `web/index.html`
- service worker: automatically generated during Flutter Web build
- installable icons: `web/icons/`

### Recommended PWA build

```bash
flutter build web --release --pwa-strategy=offline-first
```

The generated folder is `build/web`.

### Test PWA installation

1. Serve `build/web` over HTTPS (or on localhost for local testing).
2. Open the app in Chrome/Edge.
3. Check the install option ("Install app").

### Important notes

- PWA caching is handled by the Flutter service worker.
- After a new deployment, a full reload may be required to get the latest version.

### Regenerate web icons (branding)

PWA icons are generated from `assets/images/logo.png`.

```bash
dart run flutter_launcher_icons
```

### PWA quality checks (recommended)

- Open DevTools > Application to verify `manifest.json` and the service worker.
- Run a Lighthouse audit (PWA category) on a release build.
