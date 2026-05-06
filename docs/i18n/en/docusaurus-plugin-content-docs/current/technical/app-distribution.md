---
sidebar_position: 6
---

# Application Distribution

This document explains how the native and web versions of Novaville are compiled, renamed, and distributed through Continuous Integration (CI).

## Release Workflow

Distribution is handled by the GitHub Actions workflow named `flutter_release.yml`. It runs on every push to `main` and upon creating Git Tags.

### 1. Automatic Renaming (Tooling)

By default, Flutter uses the internal directory name (here `frontend`) to name the executables (e.g., `frontend.apk`, the app shows as "frontend" on user devices).

To fix this transparently and automatically, we use the `rename` community package. During every CI build, or Docker image build, the following commands are executed:

```bash
dart pub global activate rename
export PATH="$PATH":"$HOME/.pub-cache/bin"
rename setAppName --targets ios,android,macos,windows,linux --value "Novaville"
```

This guarantees the compiled application will always bear the correct name for the end user. *(Note: If you edit the frontend Dockerfile, ensure these exact lines are added just before `flutter build web`!)*

### 2. Targeted Compilation & Artifacts

The workflow compiles the application for Android (APK & AAB), Linux, Windows (`.exe` Installer via Inno Setup), macOS/iOS, and Web (PWA). Output files are temporarily stored as **GitHub Artifacts** (14-day retention, requires a GitHub login to download).

### 3. GitHub Releases

This is the main, permanent distribution method for the application. To trigger a public distribution of the executables, push a Git Tag starting with `v` or `V` (e.g., `V1.0.0`):

```bash
git tag V1.0.0
git push origin V1.0.0
```

The CI will automatically download all built artifacts, bundle them, and upload them publicly to the repository's **Releases** page. These public links are the ones referenced on the "Downloads" page of this documentation.