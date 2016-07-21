#!/bin/bash

set -euo pipefail

# Validate environment variables
: "${REDIRECT_DEST:?Set REDIRECT_DEST using --env}"
: "${SSL_CERT:?Set SSL_CERT using --env}"
: "${SSL_KEY:?Set SSL_KEY using --env}"

# SSL certificate
cat <<EOF > /server.crt
${SSL_CERT}
EOF

# SSL key
cat <<EOF > /server.key
${SSL_KEY}
EOF

# Template an nginx.conf
cat <<EOF >/etc/nginx/nginx.conf
user nginx;
worker_processes 2;

events {
  worker_connections 1024;
}
EOF

cat <<EOF >>/etc/nginx/nginx.conf

http {
  server_tokens off;
  access_log /var/log/nginx/access.log;
  error_log /var/log/nginx/error.log;

  server {
    return 302 ${REDIRECT_DEST}\$request_uri;
  }

  server {
    listen 443 ssl;
    ssl_certificate /server.crt;
    ssl_certificate_key /server.key;
    ssl_prefer_server_ciphers on;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  }
}
EOF

echo "Redirecting to ${REDIRECT_DEST}"

# Launch nginx in the foreground
/usr/sbin/nginx -g "daemon off;"
