#!/bin/bash

# Цвета
B_GREEN="\e[32m"
B_YELLOW="\e[33m"
B_RED="\e[31m"
NO_COLOR="\e[0m"

ENV_FILE="$HOME/.monitor_env"
DISK_PID_FILE="/tmp/monitor_disk_pid"
MEM_PID_FILE="/tmp/monitor_mem_pid"

# Проверка и загрузка .env
init_env() {
  if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
  fi

  changed=false

  if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
    read -p "Введите Telegram Bot Token: " TELEGRAM_BOT_TOKEN
    changed=true
  fi

  if [ -z "$TELEGRAM_CHAT_ID" ]; then
    read -p "Введите Telegram Chat ID: " TELEGRAM_CHAT_ID
    changed=true
  fi

  if [ -z "$SERVER_NAME" ]; then
    read -p "Введите имя сервера (например: srv-node-01): " SERVER_NAME
    changed=true
  fi

  if [ "$changed" = true ]; then
    echo "TELEGRAM_BOT_TOKEN=\"$TELEGRAM_BOT_TOKEN\"" > "$ENV_FILE"
    echo "TELEGRAM_CHAT_ID=\"$TELEGRAM_CHAT_ID\"" >> "$ENV_FILE"
    echo "SERVER_NAME=\"$SERVER_NAME\"" >> "$ENV_FILE"
    echo -e "${B_GREEN}✅ Настройки сохранены в $ENV_FILE${NO_COLOR}"
  fi
}

# Отправка сообщений в Telegram
send_telegram_alert() {
  local message="$1"
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d parse_mode="HTML" \
    -d text="<b>📡 $SERVER_NAME</b>%0A%0A${message}" > /dev/null
}

# Проверка диска
check_disk_space() {
  while true; do
    disk_usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')

    if [ "$disk_usage" -ge 100 ]; then
      send_telegram_alert "❌ ДИСК ЗАПОЛНЕН НА 100%! Требуется немедленное вмешательство!"
    elif [ "$disk_usage" -ge 98 ]; then
      send_telegram_alert "🚨 Диск почти заполнен: ${disk_usage}%! Проверьте, освободите место."
    elif [ "$disk_usage" -ge 96 ]; then
      send_telegram_alert "⚠️ Предупреждение: диск заполнен на ${disk_usage}%. Задумайтесь о том, чтобы освободить место."
    fi

    sleep 300
  done
}

# Проверка памяти
check_memory() {
  while true; do
    mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    mem_used=$((mem_total - mem_available))
    mem_usage_percent=$((mem_used * 100 / mem_total))

    if [ "$mem_usage_percent" -ge 99 ]; then
      send_telegram_alert "❌ ОЗУ почти полностью занята (${mem_usage_percent}%). Требуется немедленная проверка!"
    elif [ "$mem_usage_percent" -ge 95 ]; then
      send_telegram_alert "🚨 Высокое потребление памяти: ${mem_usage_percent}%. Рассмотрите возможность оптимизации."
    elif [ "$mem_usage_percent" -ge 85 ]; then
      send_telegram_alert "⚠️ Использование памяти превышает 85% (${mem_usage_percent}%)."
    fi

    sleep 300
  done
}

# Запуск мониторинга
start_monitoring() {
  if [ -f "$DISK_PID_FILE" ] || [ -f "$MEM_PID_FILE" ]; then
    echo -e "${B_YELLOW}⚠️ Мониторинг уже запущен.${NO_COLOR}"
    return
  fi

  echo -e "${B_GREEN}▶️ Запуск мониторинга ресурсов...${NO_COLOR}"

  check_disk_space & echo $! > "$DISK_PID_FILE"
  check_memory & echo $! > "$MEM_PID_FILE"

  disk_usage=$(df -h / | awk 'NR==2{print $5}')
  mem_info=$(free -h | awk '/Mem:/{print $3 " / " $2}')

  read -r -d '' message <<EOF
<b>✅ Мониторинг ресурсов запущен</b>

📊 <b>Ресурсы:</b>
• 💾 Диск: $disk_usage
• 🧠 RAM: $mem_info
EOF

  send_telegram_alert "$message"
}

# Остановка мониторинга
stop_monitoring() {
  if [ -f "$DISK_PID_FILE" ]; then
    kill "$(cat "$DISK_PID_FILE")" 2>/dev/null && echo -e "${B_RED}⛔ Диск-монитор остановлен.${NO_COLOR}"
    rm -f "$DISK_PID_FILE"
  fi
  if [ -f "$MEM_PID_FILE" ]; then
    kill "$(cat "$MEM_PID_FILE")" 2>/dev/null && echo -e "${B_RED}⛔ RAM-монитор остановлен.${NO_COLOR}"
    rm -f "$MEM_PID_FILE"
  fi
  send_telegram_alert "⛔ Мониторинг ресурсов остановлен"
}

# Проверка статуса
check_status() {
  echo -e "${B_YELLOW}📊 Статус мониторинга ресурсов:${NO_COLOR}"

  if [ -f "$DISK_PID_FILE" ]; then
    disk_pid=$(cat "$DISK_PID_FILE")
    if kill -0 "$disk_pid" 2>/dev/null; then
      start_time=$(ps -p "$disk_pid" -o lstart=)
      echo -e "💾 Диск-монитор: ${B_GREEN}работает${NO_COLOR} (PID: $disk_pid, запущен: $start_time)"
    else
      echo -e "💾 Диск-монитор: ${B_RED}остановлен${NO_COLOR} (PID: $disk_pid — неактивен)"
    fi
  else
    echo -e "💾 Диск-монитор: ${B_RED}остановлен${NO_COLOR}"
  fi

  if [ -f "$MEM_PID_FILE" ]; then
    mem_pid=$(cat "$MEM_PID_FILE")
    if kill -0 "$mem_pid" 2>/dev/null; then
      start_time=$(ps -p "$mem_pid" -o lstart=)
      echo -e "🧠 RAM-монитор: ${B_GREEN}работает${NO_COLOR} (PID: $mem_pid, запущен: $start_time)"
    else
      echo -e "🧠 RAM-монитор: ${B_RED}остановлен${NO_COLOR} (PID: $mem_pid — неактивен)"
    fi
  else
    echo -e "🧠 RAM-монитор: ${B_RED}остановлен${NO_COLOR}"
  fi
}

# Настройка переменных окружения
setup_variables() {
  echo -e "${B_YELLOW}🔧 Настройка переменных окружения...${NO_COLOR}"
  read -p "Введите Telegram Bot Token: " TELEGRAM_BOT_TOKEN
  read -p "Введите Telegram Chat ID: " TELEGRAM_CHAT_ID
  read -p "Введите имя сервера: " SERVER_NAME

  echo "TELEGRAM_BOT_TOKEN=\"$TELEGRAM_BOT_TOKEN\"" > "$ENV_FILE"
  echo "TELEGRAM_CHAT_ID=\"$TELEGRAM_CHAT_ID\"" >> "$ENV_FILE"
  echo "SERVER_NAME=\"$SERVER_NAME\"" >> "$ENV_FILE"

  echo -e "${B_GREEN}✅ Все переменные успешно сохранены.${NO_COLOR}"
}


# Меню
menu() {
  echo
  echo -e "${B_YELLOW}========= 🛠 Меню управления мониторингом ресурсов =========${NO_COLOR}"
  echo -e "1) ▶️  Запустить мониторинг"
  echo -e "2) ⏹  Остановить мониторинг"
  echo -e "3) ℹ️  Проверить статус мониторинга"
  echo -e "4) ⚙️  Настроить переменные"
  echo -e "5) ❌ Выход"
  echo -e "${B_YELLOW}==========================================================${NO_COLOR}"
}

# Основной блок
init_env

while true; do
  menu
  read -p "Выберите действие: " choice
    case $choice in
    1) start_monitoring ;;
    2) stop_monitoring ;;
    3) check_status ;;
    4) setup_variables ;;
    5) echo "Выход..."; return ;;
    *) echo -e "${B_RED}❗ Неверный выбор${NO_COLOR}" ;;
  esac
done

