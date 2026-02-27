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
  --pwa-strategy=offline-first \
      --dart-define=FLUTTER_BACKEND_API=${FLUTTER_BACKEND_API} \
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

  # En-têtes sécurité (compatibles Flutter Web/PWA)
  add_header X-Content-Type-Options "nosniff" always;
  add_header X-Frame-Options "DENY" always;
  add_header Referrer-Policy "strict-origin-when-cross-origin" always;
  add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
  add_header Cross-Origin-Opener-Policy "same-origin" always;
  add_header Cross-Origin-Resource-Policy "same-origin" always;
  add_header Content-Security-Policy "default-src 'self'; base-uri 'self'; object-src 'none'; frame-ancestors 'none'; img-src 'self' data: blob:; style-src 'self' 'unsafe-inline'; script-src 'self' 'wasm-unsafe-eval'; connect-src 'self' https: http: ws: wss:; font-src 'self' data:;" always;

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