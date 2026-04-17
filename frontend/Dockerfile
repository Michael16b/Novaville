##########
# STAGE 1: Build Flutter Web
##########
FROM ghcr.io/cirruslabs/flutter:stable AS flutter-builder

WORKDIR /app

# Pré-copie pour le cache des dépendances
COPY pubspec.yaml ./
RUN flutter pub get

# Copie du code source
COPY . /app/

# Build args (injectés depuis docker-compose ou GitHub Actions)
ARG FLUTTER_BACKEND_API
ARG ENVIRONMENT=production

# --- CONFIGURATION DE L'URL DU BACKEND ---
# On crée un fichier .env avec la clé API_BASE_URL que AppConfig lit via flutter_dotenv.
# Les valeurs String.fromEnvironment et les assets Flutter sont figés à la compilation.
#
# FLUTTER_BACKEND_API peut être :
#   - Vide (défaut) : l'application utilise des URLs relatives (/api/...).
#     Nginx proxie /api/ vers le conteneur backend. C'est le mode recommandé
#     pour la production Azure car il est indépendant du domaine Azure.
#   - http://localhost : Docker local, Nginx proxy sur le port 80.
#   - https://votre-domaine.com : URL publique explicite (optionnel).
#
# IMPORTANT: localhost:8000 ne doit JAMAIS être utilisé — c'est le port interne du backend,
# inaccessible depuis le navigateur des utilisateurs finaux en production.
RUN BACKEND_API="${FLUTTER_BACKEND_API:-}" && \
    if echo "$BACKEND_API" | grep -qF 'localhost:8000'; then \
      echo "ERROR: FLUTTER_BACKEND_API ne doit pas être http://localhost:8000." >&2 && \
      echo "       localhost:8000 est le port interne du backend, inaccessible depuis" >&2 && \
      echo "       le navigateur des utilisateurs. Utilisez :" >&2 && \
      echo "         - http://localhost  (Docker local, Nginx proxy sur le port 80)" >&2 && \
      echo "         - https://votre-domaine.com  (production)" >&2 && \
      exit 1; \
    fi && \
    echo "API_BASE_URL=${BACKEND_API}" > .env && \
    echo "ENVIRONMENT=${ENVIRONMENT}" >> .env

# Configuration et build web release
# On utilise --dart-define pour injecter les variables directement dans le code
RUN flutter config --enable-web && \
    BACKEND_API="${FLUTTER_BACKEND_API:-}" && \
    flutter build web --release --verbose \
      --pwa-strategy=offline-first \
      --dart-define=FLUTTER_BACKEND_API=${BACKEND_API} \
      --dart-define=ENVIRONMENT=${ENVIRONMENT}

##########
# STAGE 2: Serveur Nginx
##########
FROM nginxinc/nginx-unprivileged:stable-alpine AS frontend-web

COPY --from=flutter-builder /app/build/web/ /usr/share/nginx/html/

# Configuration Nginx SPA avec proxy API pour Azure multi-container
RUN cat > /etc/nginx/conf.d/default.conf <<'EOF'
server {
  listen 8080;
  server_name _;
  server_tokens off;
  root /usr/share/nginx/html;
  index index.html;

  # ✅ AJOUTE CES DEUX LIGNES
  resolver 127.0.0.11 valid=30s ipv6=off;
  set $backend "http://backend:8000";

  add_header X-Content-Type-Options "nosniff" always;
  # ... reste des headers inchangé ...

  location ^~ /api/ {
    proxy_pass $backend;  # ✅ Variable au lieu de valeur directe
    proxy_set_header Host $host;
    # ... reste inchangé ...
  }

  location ^~ /admin/ {
    proxy_pass $backend;  # ✅ idem
    proxy_set_header Host $host;
    # ... reste inchangé ...
  }

  location ^~ /grappelli/ {
    proxy_pass $backend;
    proxy_set_header Host $host;
  }

  location ^~ /static/ {
    proxy_pass $backend;  # ✅ idem
    proxy_set_header Host $host;
    expires 1y;
    add_header Cache-Control "public, immutable";
  }

  location ^~ /media/ {
    proxy_pass $backend;  # ✅ idem
    proxy_set_header Host $host;
    expires 1y;
    add_header Cache-Control "public, max-age=31536000";
  }

  location / {
    try_files $uri $uri/ /index.html;
  }

  # Fichiers d'entree et fichiers racine non versionnes: toujours revalider
  # pour recuperer la derniere release
  location = /index.html {
    try_files $uri =404;
    expires -1;
    add_header Cache-Control "no-cache, must-revalidate" always;
  }

  location = /browserconfig.xml {
    try_files $uri =404;
    expires -1;
    add_header Cache-Control "no-cache, must-revalidate" always;
  }
  location = /main.dart.js {
    try_files $uri =404;
    expires -1;
    add_header Cache-Control "no-cache, must-revalidate" always;
  }

  location = /flutter_bootstrap.js {
    try_files $uri =404;
    expires -1;
    add_header Cache-Control "no-cache, must-revalidate" always;
  }

  location = /flutter.js {
    try_files $uri =404;
    expires -1;
    add_header Cache-Control "no-cache, must-revalidate" always;
  }

  location = /flutter_service_worker.js {
    try_files $uri =404;
    expires -1;
    add_header Service-Worker-Allowed "/" always;
    add_header Cache-Control "no-cache, must-revalidate" always;
  }

  location = /manifest.json {
    try_files $uri =404;
    add_header Content-Type "application/manifest+json" always;
    add_header Cache-Control "no-cache, must-revalidate" always;
  }

  # Assets Flutter versionnes: cache long
  location ^~ /assets/ {
    try_files $uri =404;
    expires 1y;
    add_header Cache-Control "public, immutable" always;
  }

  # CanvasKit n'est pas garanti comme versionne par l'URL entre versions Flutter:
  # on garde un cache court pour eviter de servir durablement une version
  # incompatible apres mise a jour de l'application.
  location ^~ /canvaskit/ {
    try_files $uri =404;
    expires 1h;
    add_header Cache-Control "public, max-age=3600" always;
  }

  location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|webp|woff|woff2|ttf|eot)$ {
    try_files $uri =404;
    expires 1h;
    add_header Cache-Control "public, max-age=3600" always;
  }
}
EOF

EXPOSE 8080