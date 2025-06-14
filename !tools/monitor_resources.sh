#!/bin/bash

# Цвета
B_GREEN="\e[32m"
B_YELLOW="\e[33m"
B_RED="\e[31m"
NO_COLOR="\e[0m"

ENV_FILE="$HOME/.monitor_env"
DISK_PID_FILE="/tmp/monitor_disk_pid"
MEM_PID_FILE="/tmp/monitor_mem_pid"

# Загрузка .env, если существует
if [ -f "$ENV_FILE" ]; then
  source "$ENV_FILE"
fi

# Настройка Telegram
setup_telegram() {
  echo -e "${B_YELLOW}🔧 Настройка Telegram...${NO_COLOR}"
  read -p "Введите Telegram Bot Token: " TELEGRAM_BOT_TOKEN
  read -p "Введите Telegram Chat ID: " TELEGRAM_CHAT_ID
  echo "TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN" > "$ENV_FILE"
  echo "TELEGRAM_CHAT_ID=$TELEGRAM_CHAT_ID" >> "$ENV_FILE"
  echo -e "${B_GREEN}✅ Telegram настройки сохранены.${NO_COLOR}"
}

# Отправка сообщений в Telegram
send_telegram_alert() {
  local message="$1"
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d parse_mode="HTML" \
    -d text="$message" > /dev/null
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
  local status=""
  if [ -f "$DISK_PID_FILE" ] && kill -0 "$(cat "$DISK_PID_FILE")" 2>/dev/null; then
    status+="💾 Диск-монитор: <b>работает</b>\n"
  else
    status+="💾 Диск-монитор: <b>остановлен</b>\n"
  fi

  if [ -f "$MEM_PID_FILE" ] && kill -0 "$(cat "$MEM_PID_FILE")" 2>/dev/null; then
    status+="🧠 RAM-монитор: <b>работает</b>"
  else
    status+="🧠 RAM-монитор: <b>остановлен</b>"
  fi

  echo -e "${status//\\n/$'\n'}"
}

# Меню
menu() {
  echo
  echo -e "${B_YELLOW}========= 🛠 Меню управления мониторингом ресурсов =========${NO_COLOR}"
  echo -e "1) ▶️  Запустить мониторинг"
  echo -e "2) ⏹  Остановить мониторинг"
  echo -e "3) ℹ️  Проверить статус мониторинга"
  echo -e "4) ⚙️  Настроить Telegram"
  echo -e "5) ❌ Выход"
  echo -e "${B_YELLOW}===========================================_

