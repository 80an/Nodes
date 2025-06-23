#!/bin/bash

ENV_FILE="/root/.nock_monitor_env"
LOG_FILE="/root/screenlog.0"
BACKUP_FILE="/root/screenlog.0.bak"

# === Загрузка конфигурации или запрос ===
load_config() {
  if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
  else
    echo "🔐 Введите Telegram Bot Token:"
    read -r BOT_TOKEN
    echo "💬 Введите Chat ID:"
    read -r CHAT_ID
    echo "🖥 Введите имя сервера:"
    read -r SERVER_NAME
    echo "⏱ Интервал проверки в часах (например: 4):"
    read -r INTERVAL_HOURS
    INTERVAL=$((INTERVAL_HOURS * 3600))

    cat <<EOF > "$ENV_FILE"
BOT_TOKEN="$BOT_TOKEN"
CHAT_ID="$CHAT_ID"
SERVER_NAME="$SERVER_NAME"
INTERVAL=$INTERVAL
EOF
  fi
}

# === Фоновая функция мониторинга ===
monitor_loop() {
  while true; do
    current_height=$(grep "added to validated blocks at" "$LOG_FILE" | tail -n 1 | awk '{print $(NF-5)}')
    max_seen_height=$(grep "heard block" "$LOG_FILE" | tail -n 100 | awk '{print $(NF-5)}' | sed 's/\.//' | sort -nr | head -n 1)

    message="🧱 <b>Блоки ноды: $SERVER_NAME</b>
• 📥 Текущий блок: <code>$current_height</code>
• 🌐 Увиденная высота сети: <code>$max_seen_height</code>"

    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
         -d chat_id="$CHAT_ID" \
         -d parse_mode="HTML" \
         -d text="$message"

    # Ротация логов
    if [[ -f "$LOG_FILE" ]]; then
      cp "$LOG_FILE" "$BACKUP_FILE"
      tail -n 1000 "$LOG_FILE" > "${LOG_FILE}.tmp"
      mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi

    sleep "$INTERVAL"
  done
}

# === Запуск ===
load_config
echo "✅ Мониторинг блоков \"$SERVER_NAME\" запущен (раз в $((INTERVAL / 3600)) ч)..."
monitor_loop & disown
