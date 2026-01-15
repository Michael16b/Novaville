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

# Build args (injectés depuis GitHub Actions)
ARG API_URL=http://localhost:8000
ARG ENVIRONMENT=production

# --- SOLUTION AU PROBLÈME .ENV ---
# On crée un fichier .env minimaliste pour satisfaire le compilateur Flutter
# même si le fichier physique est absent du repo.
RUN touch .env && \
    echo "API_URL=${API_URL}" > .env && \
    echo "ENVIRONMENT=${ENVIRONMENT}" >> .env

# Configuration et build web release
# On utilise --dart-define pour injecter les variables directement dans le code
RUN flutter config --enable-web && \
    flutter build web --release --verbose \
      --dart-define=API_URL=${API_URL} \
      --dart-define=ENVIRONMENT=${ENVIRONMENT}

##########
# STAGE 2: Serveur Nginx
##########
FROM nginx:alpine AS frontend-web

COPY --from=flutter-builder /app/build/web/ /usr/share/nginx/html/

# Configuration Nginx SPA (On garde ta config qui est excellente)
RUN cat > /etc/nginx/conf.d/default.conf <<'EOF'
server {
  listen 80;
  server_name _;
  root /usr/share/nginx/html;
  index index.html;

  location / {
    try_files $uri $uri/ /index.html;
  }

  # Sécurité et Cache (config inchangée)
  location ~* \.(manifest|appcache|html?|xml|json)$ {
    expires -1;
    add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0";
  }

  location = /flutter_service_worker.js {
    try_files $uri =404;
    expires -1;
    add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0";
  }

  location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|webp|woff|woff2|ttf|eot)$ {
    try_files $uri =404;
    expires 1y;
    add_header Cache-Control "public, immutable";
  }
}
EOF

EXPOSE 80