#!/bin/sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
  echo "Запусти скрипт от root: sudo ./script.sh"
  exit 1
fi

master_ip=""
domain=""
email=""
xhttp_path=""

while [ $# -gt 0 ]; do
  case "$1" in
    --master_ip=*)
      master_ip="${1#*=}"
      ;;
    --domain=*)
      domain="${1#*=}"
      ;;
    --email=*)
      email="${1#*=}"
      ;;
    --xhttp_path=*)
      xhttp_path="${1#*=}"
      ;;
    --help|-h)
      echo "Usage:"
      echo "  $0 --master_ip=IP --domain=DOMAIN --email=EMAIL --xhttp_path=PATH"
      exit 0
      ;;
    *)
      echo "Неизвестный аргумент: $1"
      echo "Используй: $0 --help"
      exit 1
      ;;
  esac
  shift
done

if [ -z "$master_ip" ]; then
  echo "Ошибка: не указан --master_ip"
  exit 1
fi

if [ -z "$domain" ]; then
  echo "Ошибка: не указан --domain"
  exit 1
fi

if [ -z "$email" ]; then
  echo "Ошибка: не указан --email"
  exit 1
fi

if [ -z "$xhttp_path" ]; then
  echo "Ошибка: не указан --xhttp_path"
  exit 1
fi

echo "================================================"
echo "Начало установки"
echo "================================================"

apt update
apt upgrade -y
apt install -y nginx certbot ufw

echo "================================================"
echo "Настраиваем ufw"
echo "================================================"

ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow from "$master_ip" to any port 2222 proto tcp
ufw --force enable

echo "================================================"
echo "Настройка базового html"
echo "================================================"

mkdir -p /var/www/html 
chown -R www-data:www-data /var/www/html

echo '<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>CHANGE ME</title>
  </head>
  <body>
    <pre>vim /var/www/html/index.html</pre>
  </body>
</html>' > /var/www/html/index.html

echo "================================================"
echo "Настройка конфига nginx без ssl"
echo "================================================"

echo "server {
    listen 80;
    listen [::]:80;
    server_name $domain;

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}" > "/etc/nginx/sites-available/$domain"

ln -sf "/etc/nginx/sites-available/$domain" /etc/nginx/sites-enabled/

echo "================================================"
echo "Перезагрузка nginx"
echo "================================================"

nginx -t
systemctl reload nginx

echo "================================================"
echo "Получение сертификатов"
echo "================================================"

certbot certonly --webroot \
  -w /var/www/html \
  -d "$domain" \
  --email "$email" \
  --agree-tos \
  --non-interactive

echo "================================================"
echo "Настройка конфига nginx"
echo "================================================"

echo "
server {
    listen 127.0.0.1:8443 ssl;
    server_name $domain;

    root /var/www/html;
    index index.html;

    ssl_certificate     /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;

    ssl_protocols TLSv1.3;
    ssl_prefer_server_ciphers off;

    add_header Strict-Transport-Security \"max-age=31536000; includeSubDomains\" always;

    server_tokens off;

    access_log off;
    error_log /var/log/nginx/error.log warn;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location $xhttp_path {
        default_type application/json;
        return 401 '{\"status\": \"unauthorized\"}';
    }
}" >> "/etc/nginx/sites-available/$domain"

echo "================================================"
echo "Перезагрузка nginx"
echo "================================================"

nginx -t
systemctl reload nginx

echo "================================================"
echo "Установка docker"
echo "================================================"

curl -fsSL https://get.docker.com | sh

echo "================================================"
echo "Создание папки для remnanode"
echo "================================================"

mkdir -p /opt/remnanode

echo "================================================"
echo "Автоматическая настройка завершена"
echo "Перейдите в папку - \"cd /opt/remnanode\""
echo "Добавьте docker compose - \"vim docker-compose.yml\""
echo "Запустите docker compose - \"docker compose up -d\""
echo "================================================"