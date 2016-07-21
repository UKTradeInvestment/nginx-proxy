#!/bin/bash

set -euo pipefail

# Validate environment variables
: "${REDIRECT_DEST:?Set REDIRECT_DEST using --env}"

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
}
EOF

echo "Redirecting to ${REDIRECT_DEST}"

# Launch nginx in the foreground
/usr/sbin/nginx -g "daemon off;"
