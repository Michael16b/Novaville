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
ARG API_URL
ARG ENVIRONMENT=production

# --- SOLUTION AU PROBLÈME .ENV ---
# On crée un fichier .env minimaliste pour satisfaire le compilateur Flutter
# même si le fichier physique est absent du repo.
RUN touch .env && \
  BACKEND_API="${FLUTTER_BACKEND_API:-${API_URL:-http://localhost:8000}}" && \
  echo "FLUTTER_BACKEND_API=${BACKEND_API}" > .env && \
  echo "ENVIRONMENT=${ENVIRONMENT}" >> .env

# Configuration et build web release
# On utilise --dart-define pour injecter les variables directement dans le code
RUN flutter config --enable-web && \
    BACKEND_API="${FLUTTER_BACKEND_API:-${API_URL:-http://localhost:8000}}" && \
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

  location /api/ {
    proxy_pass $backend;  # ✅ Variable au lieu de valeur directe
    proxy_set_header Host $host;
    # ... reste inchangé ...
  }

  location /admin/ {
    proxy_pass $backend;  # ✅ idem
    proxy_set_header Host $host;
    # ... reste inchangé ...
  }

  location /static/ {
    proxy_pass $backend;  # ✅ idem
    proxy_set_header Host $host;
    expires 1y;
    add_header Cache-Control "public, immutable";
  }

  location /media/ {
    proxy_pass $backend;  # ✅ idem
    proxy_set_header Host $host;
    expires 1y;
    add_header Cache-Control "public, max-age=31536000";
  }

  location / {
    try_files $uri $uri/ /index.html;
  }

  # Sécurité et Cache pour fichiers Flutter
  location ~* \.(manifest|appcache|html?|xml|json)$ {
    expires -1;
    add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0" always;
  }

  location = /flutter_service_worker.js {
    try_files $uri =404;
    expires -1;
    add_header Service-Worker-Allowed "/" always;
    add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0" always;
  }

  location = /manifest.json {
    try_files $uri =404;
    add_header Content-Type "application/manifest+json" always;
    add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0" always;
  }

  location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|webp|woff|woff2|ttf|eot)$ {
    try_files $uri =404;
    expires 1y;
    add_header Cache-Control "public, immutable" always;
  }
}
EOF

EXPOSE 8080