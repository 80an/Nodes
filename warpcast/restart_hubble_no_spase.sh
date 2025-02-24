#!/bin/bash

# Название screen-сессии
SCREEN_SESSION="hubble_install"

# Папка Hubble
HUBBLE_DIR="$HOME/hubble"

# Проверяем наличие screen
if ! command -v screen &> /dev/null; then
    echo "Screen не установлен. Устанавливаем..."
    sudo apt update && sudo apt install screen -y
fi

# Удаление всех старых screen-сессий
echo "Удаляем все старые screen-сессии..."
screen -ls | grep Detached | awk '{print $1}' | xargs -r screen -X -S quit

# Запуск установки Hubble в screen-сессии
screen -dmS "$SCREEN_SESSION" bash -c "
    echo '=== Начало переустановки Hubble ==='

    sleep 5

    # Остановка Docker-контейнеров
    if [ -d \"$HUBBLE_DIR\" ]; then
        cd \"$HUBBLE_DIR\" && docker compose down
    fi

    # Удаление старых данных
    echo 'Удаляем старые данные...'
    rm -rf \"$HUBBLE_DIR\"

    # Очистка Docker и освобождение места
    echo 'Очищаем Docker...'
    docker system prune -af
    docker volume prune -f

    # Удаление старых логов
    echo 'Удаляем старые логи...'
    sudo journalctl --vacuum-size=100M
    sudo apt autoremove -y

    # Обновление системы
    echo 'Обновляем систему...'
    sudo apt update && sudo apt upgrade -y

    # Загрузка и установка Hubble
    echo 'Загружаем и устанавливаем Hubble...'
    curl -sSL https://download.thehubble.xyz/bootstrap.sh | bash

    # Подготавливаем работу с портами
    echo 'Настраиваем порты...'
    sudo apt-get install -y iptables-persistent
    sudo iptables -A INPUT -p tcp --dport 2281 -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 2282 -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 2283 -j ACCEPT
    sudo netfilter-persistent save
    sudo iptables -L -v -n

    echo '=== Переустановка завершена ==='
"

echo "Установка Hubble запущена в screen-сессии: $SCREEN_SESSION"
echo "Для просмотра хода установки выполните команду: screen -r $SCREEN_SESSION"
