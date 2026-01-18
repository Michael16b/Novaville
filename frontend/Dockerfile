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
# ARG FLUTTER_BACKEND_API=http://localhost:8000
ARG ENVIRONMENT=production

# --- SOLUTION AU PROBLÈME .ENV ---
# On crée un fichier .env minimaliste pour satisfaire le compilateur Flutter
# même si le fichier physique est absent du repo.
RUN touch .env && \
    echo "FLUTTER_BACKEND_API=${FLUTTER_BACKEND_API}" > .env && \
    echo "ENVIRONMENT=${ENVIRONMENT}" >> .env

# Configuration et build web release
# On utilise --dart-define pour injecter les variables directement dans le code
RUN flutter config --enable-web && \
    flutter build web --release --verbose \
      --dart-define=FLUTTER_BACKEND_API=${FLUTTER_BACKEND_API} \
      --dart-define=ENVIRONMENT=${ENVIRONMENT}

##########
# STAGE 2: Serveur Nginx
##########
FROM nginx:alpine AS frontend-web

COPY --from=flutter-builder /app/build/web/ /usr/share/nginx/html/

# Configuration Nginx SPA avec proxy API pour Azure multi-container
RUN cat > /etc/nginx/conf.d/default.conf <<'EOF'
server {
  listen 80;
  server_name _;
  root /usr/share/nginx/html;
  index index.html;

  # Proxy pour les requêtes API vers le backend Django
  location /api/ {
    proxy_pass http://backend:8000;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Port $server_port;
    
    # Timeout settings for long-running requests
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;
  }

  # Proxy pour l'admin Django (optionnel, peut être désactivé en prod)
  location /admin/ {
    proxy_pass http://backend:8000;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Port $server_port;
  }

  # Proxy pour les fichiers statiques Django
  location /static/ {
    proxy_pass http://backend:8000;
    proxy_set_header Host $host;
    expires 1y;
    add_header Cache-Control "public, immutable";
  }

  # Proxy pour les fichiers media Django
  location /media/ {
    proxy_pass http://backend:8000;
    proxy_set_header Host $host;
    expires 1y;
    add_header Cache-Control "public, max-age=31536000";
  }

  # Flutter Web App (doit être après les locations spécifiques)
  location / {
    try_files $uri $uri/ /index.html;
  }

  # Sécurité et Cache pour fichiers Flutter
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