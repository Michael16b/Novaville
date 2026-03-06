---
sidebar_position: 1
---

# Welcome to Novaville Docs

Welcome to the **Novaville** documentation — a citizen participation platform. This doc mirrors the frontend UI (Novaville logo, palette, and clear sections) and guides you from the first run to advanced integrations.

## 📚 Audience

- **Developers**: architecture, API, examples, security
- **Ops**: Docker/Compose deployment, env vars, monitoring
- **End users**: UI walkthrough aligned with the frontend
- **Clients**: functional scope, roadmap, indicative SLAs

## 🚀 Where to start

### For developers

- [Getting started](getting-started/introduction): local setup
- [Architecture](technical/architecture): Django backend, Flutter frontend, PostgreSQL, JWT auth
- [API Overview](api/overview): schemas, status codes, pagination

### For users

- [User manual](user-manual/intro): login, navigation, reports
- UI consistent with the frontend: same logo, colors, wording

### For API integration

- [Auth](api/auth/login) / [Refresh](api/auth/refresh-token): cURL, JS, Python, Dart examples

## 🏗️ Architecture

- **Backend**: Django REST + JWT, PostgreSQL
- **Frontend**: Flutter (mobile/web), Novaville theme
- **Infra**: Docker/Compose (api, front, docs, db)
- **Security**: JWT, CORS, hardened Nginx headers

## 📖 Docs structure

```
📁 Documentation
├── 📘 Getting Started — install & configure
├── 🔧 Technical Docs — architecture & internals
├── 🌐 API Docs — REST endpoints & auth
└── 📗 User Manual — end-user guides
```

## 🤝 Contribute

Maintained regularly. For questions or suggestions, open an issue on the [GitHub repo](https://github.com/Michael16b/Novaville).

## 📝 Release notes

See the [Release notes](/blog) for the latest updates and improvements.
