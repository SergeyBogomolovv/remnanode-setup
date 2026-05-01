# Remnanode setup

Скрипт для первоначальной настройки VPS для remnanode.

## Что делает

- Обновляет систему
- Устанавливает:
  - nginx
  - certbot
  - ufw
  - docker
- Настраивает UFW:
  - открывает `22/tcp`
  - открывает `80/tcp`
  - открывает `443/tcp`
  - открывает `2222/tcp` только для указанного `master_ip`
- Создаёт базовую директорию сайта:
  - `/var/www/html`
- Создаёт базовый `index.html`
- Создаёт nginx-конфиг для домена
- Получает SSL-сертификат через Let's Encrypt
- Дописывает SSL nginx-конфиг
- Создаёт директорию:
  - `/opt/remnanode`

## Запуск

```sh
wget -qO- https://raw.githubusercontent.com/SergeyBogomolovv/remnanode-setup/refs/heads/main/script.sh | sudo sh -s -- \
  --master_ip=<ip панели> \
  --domain=<домен который привязан к vps> \
  --email=<email для LE> \
  --xhttp_path=<путь для xhttp>
```