#!/bin/bash

set -euo pipefail

# Validate environment variables
: "${VHOST:?Set VHOST using --env}"
: "${VHOST_ROOT:?Set VHOST_ROOT using --env}"
: "${BACKEND_HOST:?Set BACKEND_HOST using --env}"
: "${BACKEND_PORT:?Set BACKEND_PORT using --env}"

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
    server_name ${VHOST} www.${VHOST};
    root ${VHOST_ROOT};

    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    set_real_ip_from 0.0.0.0/0;
    real_ip_header X-Forwarded-For;
    real_ip_recursive on;

    gzip on;
    gzip_proxied any;
    gzip_vary on;
    gzip_types *;

    location / {
      if ($http_x_forwarded_proto = "http") {
        return 302 https://${VHOST}\$request_uri;
      }
      try_files $uri @app;
    }

    location @app {
      expires -1;
      proxy_pass http://${BACKEND_HOST}:${BACKEND_PORT};
    }
  }
}
EOF

# Launch nginx in the foreground
/usr/sbin/nginx -g "daemon off;"
