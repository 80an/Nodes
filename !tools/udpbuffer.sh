#!/bin/bash

# Берем цвета
source <(wget -qO- 'https://raw.githubusercontent.com/CBzeek/Nodes/refs/heads/main/!tools/bash-colors.sh')
B_BLUE='\033[1;34m' # Blue

BACKUP_FILE="/etc/sysctl.conf.bak_udpbuffer"
SYSCTL_FILE="/etc/sysctl.conf"

function set_udp_buffer() {
    read -p "Введите желаемый размер UDP буфера в мегабайтах (например, 2): " MB
    if ! [[ "$MB" =~ ^[0-9]+$ ]] || [ "$MB" -le 0 ]; then
        echo "Некорректное значение!"
        return
    fi
    SIZE=$((MB*1024*1024))

    # Делаем бэкап, если его еще нет
    if [ ! -f "$BACKUP_FILE" ]; then
        sudo cp "$SYSCTL_FILE" "$BACKUP_FILE"
    fi

    # Устанавливаем значения
    sudo sysctl -w net.core.rmem_max=$SIZE
    sudo sysctl -w net.core.wmem_max=$SIZE

    # Удаляем старые строки и добавляем новые
    sudo sed -i '/^net.core.rmem_max/d' "$SYSCTL_FILE"
    sudo sed -i '/^net.core.wmem_max/d' "$SYSCTL_FILE"
    echo "net.core.rmem_max=$SIZE" | sudo tee -a "$SYSCTL_FILE" >/dev/null
    echo "net.core.wmem_max=$SIZE" | sudo tee -a "$SYSCTL_FILE" >/dev/null

    sudo sysctl -p

    echo -e "${B_GREEN}✅ UDP буфер увеличен до $MB МБ ($SIZE байт)${NO_COLOR}"
}

function restore_udp_buffer() {
    if [ ! -f "$BACKUP_FILE" ]; then
        echo "Бэкап не найден, восстановление невозможно!"
        return
    fi
    sudo cp "$BACKUP_FILE" "$SYSCTL_FILE"
    sudo sysctl -p
    echo -e "${B_GREEN}✅ Настройки UDP буфера восстановлены из бэкапа.${NO_COLOR}"
}

while true; do
    echo
    echo -e "${B_BLUE}========== Меню управления UDP буфером ==========${NO_COLOR}"
    echo "1) Задать размер буфера"
    echo "2) Вернуть настройки буфера к исходным"
    echo "3) Посмотреть текущий размер буфера"
    echo "4) Выход"
    echo -e "${B_BLUE}===============================================${NO_COLOR}"
    echo

    read -p "Выберите пункт меню (1-3): " choice

    echo

    case $choice in
        1)
            set_udp_buffer
            ;;
        2)
            restore_udp_buffer
            ;;
        3)
            sysctl net.core.rmem_default
            sysctl net.core.rmem_max
            sysctl net.core.wmem_default
            sysctl net.core.wmem_max

            ;;
        4)
            echo "Выход..."
            break
            ;;
        *)
            echo "Некорректный выбор!"
            ;;
    esac
done
