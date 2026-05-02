---
sidebar_position: 4
---

# Developer Onboarding

This document helps a new development team quickly take over the Novaville project: understand the architecture, run the code locally, run tests and contribute safely.

## Goals

- Present the overall architecture
- Describe the local development flow (setup, services, environment variables)
- Explain how to run the test suite
- Highlight production and deployment considerations

## Repository structure

Main folders:

- `backend/`: Django REST API
- `frontend/`: Flutter application (mobile/web)
- `docs/`: Documentation (Docusaurus)
- `docker-compose.yml` and `docker-compose-azure.yml`: environment definitions

## Quick start

1. Copy environment variables from `.env.example` and adapt them.
2. Start services:

```bash
docker compose up -d --build
```

API is available at `http://localhost:8000`, Frontend at `http://localhost:80`.

## Run backend tests

```bash
docker compose exec backend pytest
```

## Debugging and considerations

- `DJANGO_SECRET_KEY` and other secrets must never be committed
- Check migrations after model changes
- External integrations and production variables are in `docker-compose-azure.yml`

## More information

- Architecture: [Technical documentation](../docs/technical/architecture)
- API: [API documentation](../docs/api/overview)
- CI/CD and deployment: see workflows and `docs/DOCUMENTATION_README.md`

### Prerequisites (detailed)

- Docker & Docker Compose
- Node.js (for docs) and npm
- Flutter SDK (if working on the frontend)

### Install Flutter

- Official: https://flutter.dev

Linux (example):

```bash
# Install dependencies (e.g. Ubuntu)
sudo apt update
sudo apt install -y curl git unzip xz-utils libglu1-mesa

# Download SDK
cd ~
curl -LO https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_stable.tar.xz
tar xf flutter_linux_stable.tar.xz
export PATH="$PATH:$HOME/flutter/bin"
flutter doctor
```

Windows:

- Download installer or SDK from https://flutter.dev/docs/get-started/install/windows
- Run installer and add `flutter/bin` to PATH, then run `flutter doctor` in PowerShell.

macOS:

```bash
# Via Homebrew (recommended)
brew install flutter

# Or download manually from https://flutter.dev/docs/get-started/install/macos
# and add to PATH:
export PATH="$PATH:$HOME/Development/flutter/bin"

# Verify installation
flutter doctor
```

### Install Docker

- Official: https://www.docker.com/get-started

Windows: install Docker Desktop and enable WSL2 if prompted.

Linux (example, Ubuntu):

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker $USER
newgrp docker
docker run hello-world
```

macOS:

```bash
# Via Homebrew (recommended)
brew install docker docker-compose

# Or install Docker Desktop from https://www.docker.com/products/docker-desktop
# which includes Docker and Docker Compose

docker --version
docker compose version
```

After installing, verify: `docker --version`, `docker compose version`, `flutter --version`
