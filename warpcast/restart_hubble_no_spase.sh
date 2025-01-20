#!/bin/bash

# Папка Hubble
HUBBLE_DIR="$HOME/hubble"

# Остановка Docker-контейнеров
if [ -d "$HUBBLE_DIR" ]; then
    cd "$HUBBLE_DIR" && docker compose down
fi

# Удаление старых данных
rm -rf "$HUBBLE_DIR"

# Очистка Docker и освобождение места
docker system prune -af
docker volume prune -f

# Удаление старых логов
sudo journalctl --vacuum-size=100M
sudo apt autoremove -y

# Обновление системы
sudo apt update && sudo apt upgrade -y

# Загрузка и установка Hubble
curl -sSL https://download.thehubble.xyz/bootstrap.sh | bash

# Подготавливаем работу с портами
sudo apt-get install iptables-persistent -y && sudo netfilter-persistent save

# Открываем порты
sudo iptables -A INPUT -p tcp --dport 2281 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 2282 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 2283 -j ACCEPT
sudo iptables-save > /etc/iptables/rules.v4
sudo iptables -L -v -n
