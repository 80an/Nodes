#!/bin/bash

# Цвета
B_GREEN="\e[32m"
B_YELLOW="\e[33m"
B_RED="\e[31m"
NO_COLOR="\e[0m"

MONITOR_PID_FILE="/tmp/monitor_pid"
ENV_FILE="$HOME/.monitor_env"

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

# Получение информации о системе
get_system_info() {
  local disk_usage=$(df -h / | awk 'NR==2{print $5}')
  local mem_info=$(free -h | awk '/Mem:/{print $3 " / " $2}')
  echo -e "📊 <b>Ресурсы:</b>\n• 💾 Диск: $disk_usage\n• 🧠 RAM: $mem_info"
}

# Запуск мониторинга
start_monitoring() {
  if [ -f "$MONITOR_PID_FILE" ] && kill -0 "$(cat "$MONITOR_PID_FILE")" 2>/dev/null; then
    echo -e "${B_YELLOW}⚠️ Мониторинг уже запущен (PID $(cat $MONITOR_PID_FILE))${NO_COLOR}"
    return
  fi

  echo -e "${B_GREEN}▶️ Запуск мониторинга...${NO_COLOR}"
  #bash -c "source <(wget -qO- 'https://raw.githubusercontent.com/80an/Nodes/refs/heads/main/!tools/monitor_resources.sh')" &
  nohup bash -c "source <(wget -qO- 'https://raw.githubusercontent.com/80an/Nodes/refs/heads/main/!tools/monitor_resources.sh')" &> /dev/null &
  MONITOR_PID=$!
  echo "$MONITOR_PID" > "$MONITOR_PID_FILE"
  echo -e "${B_GREEN}✅ Мониторинг запущен с PID $MONITOR_PID${NO_COLOR}"

  # Собираем инфо о ресурсах
  local disk_usage=$(df -h / | awk 'NR==2{print $5}')
  local mem_info=$(free -h | awk '/Mem:/{print $3 " / " $2}')

  # Формируем сообщение с реальными переводами строк
  read -r -d '' message <<EOF
<b>✅ Мониторинг ресурсов запущен</b>

🆔 <code>$MONITOR_PID</code>

📊 <b>Ресурсы:</b>
• 💾 Диск: $disk_usage
• 🧠 RAM: $mem_info
EOF

  send_telegram_alert "$message"
}

# Остановка мониторинга и фоновых процессов
stop_monitoring() {
  if [ -f "$MONITOR_PID_FILE" ]; then
    MONITOR_PID=$(cat "$MONITOR_PID_FILE")
    if kill -0 "$MONITOR_PID" 2>/dev/null; then
      kill "$MONITOR_PID"
      echo -e "${B_RED}⛔ Мониторинг остановлен (PID $MONITOR_PID)${NO_COLOR}"
      rm -f "$MONITOR_PID_FILE"
      send_telegram_alert "⛔ Мониторинг остановлен (PID $MONITOR_PID)"
      
      # Остановка фоновых процессов
      pkill -f check_disk_space
      pkill -f check_memory
      echo -e "${B_RED}⛔ Фоновые процессы (диск и память) остановлены.${NO_COLOR}"
    else
      echo -e "${B_YELLOW}⚠️ Процесс мониторинга не найден. Удаляю PID-файл.${NO_COLOR}"
      rm -f "$MONITOR_PID_FILE"
    fi
  else
    echo -e "${B_RED}🚫 Мониторинг не запущен${NO_COLOR}"
  fi
}

# Проверка статуса мониторинга
check_status() {
  if [ -f "$MONITOR_PID_FILE" ]; then
    MONITOR_PID=$(cat "$MONITOR_PID_FILE")
    if kill -0 "$MONITOR_PID" 2>/dev/null; then
      echo -e "${B_GREEN}✅ Мониторинг работает (PID $MONITOR_PID)${NO_COLOR}"
    else
      echo -e "${B_YELLOW}⚠️ Мониторинг неактивен, но PID-файл существует${NO_COLOR}"
    fi
  else
    echo -e "${B_RED}❌ Мониторинг не запущен${NO_COLOR}"
  fi
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
  echo -e "${B_YELLOW}======================================================${NO_COLOR}"
}

# Основной цикл
while true; do
  menu
  read -p "Выберите действие: " choice
  case $choice in
    1) start_monitoring ;;
    2) stop_monitoring ;;
    3) check_status ;;
    4) setup_telegram ;;
    5)
      echo -e "${B_YELLOW}👋 Выход...${NO_COLOR}"
      break
      ;;
    *) echo -e "${B_RED}Неверный выбор. Повторите.${NO_COLOR}" ;;
  esac
done

# Функция проверки дискового пространства
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

    sleep 300  # Проверка каждые 5 минут
  done
}

# Функция проверки оперативной памяти
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

    sleep 300  # Проверка каждые 5 минут
  done
}

# Запуск функций в фоновом режиме
#check_disk_space &
#check_memory &
nohup bash -c 'check_disk_space' &> /dev/null &
nohup bash -c 'check_memory' &> /dev/null &
