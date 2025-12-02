###############################################
# Dockerfile (frontend) - Flutter Web (BLoC) + Nginx
# Usage:
#  docker build -f frontend/Dockerfile -t novaville-frontend \
#    --build-arg API_URL=https://api.novaville.com .
#  docker run --rm -p 80:80 novaville-frontend
###############################################

##########
# STAGE 1: Build Flutter Web (BLoC)
##########
FROM ghcr.io/cirruslabs/flutter:stable AS flutter-builder

WORKDIR /app

# Pré-copie pour le cache des dépendances (pubspec.yaml)
COPY pubspec.yaml ./
RUN flutter pub get

# Copie du code source (lib/, web/, assets/, etc.)
# Architecture BLoC attendue: lib/blocs/, lib/models/, lib/repositories/, lib/ui/
COPY . /app/

# Build args pour variables d'environnement injectées au build
ARG API_URL=http://localhost:8000
ARG ENVIRONMENT=production

# Configuration et build web release
RUN echo "API_URL=${API_URL}" && \
    echo "ENVIRONMENT=${ENVIRONMENT}"

# Configuration et build web release
RUN flutter config --enable-web && \
    flutter build web --release \
      --dart-define=API_URL=${API_URL} \
      --dart-define=ENVIRONMENT=${ENVIRONMENT}

##########
# STAGE 2: Serveur Nginx pour SPA Flutter
##########
FROM nginx:alpine AS frontend-web

# Copie des assets web Flutter buildés
COPY --from=flutter-builder /app/build/web/ /usr/share/nginx/html/

# Configuration Nginx optimisée pour SPA Flutter (BLoC)
# - Retourne index.html sur 404 (routage client-side)
# - Cache agressif pour assets statiques
# - Pas de cache pour index/manifest (pour mise à jour instantanée)
RUN cat > /etc/nginx/conf.d/default.conf <<'EOF'
server {
  listen 80;
  server_name _;
  root /usr/share/nginx/html;
  index index.html;

  # Compression gzip
  gzip on;
  gzip_vary on;
  gzip_min_length 1024;
  gzip_types text/plain text/css text/xml text/javascript application/javascript application/x-javascript application/xml+rss application/json;

  # SPA routing: toutes les routes inconnues -> index.html
  location / {
    try_files $uri $uri/ /index.html;
  }

  # Pas de cache pour index.html, manifest.json (mise à jour immédiate)
  location ~* \.(manifest|appcache|html?|xml|json)$ {
    expires -1;
    add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0";
  }

  # Ne pas mettre en cache le service worker Flutter : s'il est mis en cache,
  # le navigateur peut continuer à servir une ancienne version contrôlant les assets.
  location = /flutter_service_worker.js {
    try_files $uri =404;
    expires -1;
    add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0";
  }
  # Eviter aussi la mise en cache de la map si présente
  location = /flutter_service_worker.js.map {
    try_files $uri =404;
    expires -1;
    add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0";
  }

  # Cache long terme pour assets JS/CSS (hash dans le nom)
  location ~* \.(css|js)$ {
    try_files $uri =404;
    expires 1y;
    add_header Cache-Control "public, immutable";
  }

  # Cache long terme pour images et fonts
  location ~* \.(png|jpg|jpeg|gif|ico|svg|webp|woff|woff2|ttf|eot)$ {
    try_files $uri =404;
    expires 1y;
    add_header Cache-Control "public, immutable";
  }

  # Security headers
  add_header X-Frame-Options "SAMEORIGIN" always;
  add_header X-Content-Type-Options "nosniff" always;
  add_header X-XSS-Protection "1; mode=block" always;
}
EOF

EXPOSE 80

# Nginx lance automatiquement (CMD par défaut de l'image nginx:alpine)