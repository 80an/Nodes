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
    if [[ -f "$LOG_FILE" ]]; then
      current_height=$(grep -a "added to validated blocks at" "$LOG_FILE" | tail -n 1 | sed -n 's/.*added to validated blocks at \([0-9.]*\).*/\1/p')
      max_seen_height=$(grep -a "heard block" "$LOG_FILE" | tail -n 100 | sed -n 's/.*heard block.* at height \([0-9.]*\).*/\1/p' | sed 's/\.//' | sort -nr | head -n 1)

      if [[ -n "$current_height" || -n "$max_seen_height" ]]; then
        message="🧱 <b>Блоки ноды: $SERVER_NAME</b>
• 📥 Текущий блок: <code>$current_height</code>
• 🌐 Увиденная высота сети: <code>$max_seen_height</code>"

        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
          -d chat_id="$CHAT_ID" \
          -d parse_mode="HTML" \
          -d text="$message"
      else
        echo "[!] Не удалось получить значения блоков из логов." >> /var/log/nock_monitor.log
      fi

      # Ротация лога (обрезка до последних 1000 строк)
      cp "$LOG_FILE" "$BACKUP_FILE"
      tail -n 1000 "$LOG_FILE" > "${LOG_FILE}.tmp"
      mv "${LOG_FILE}.tmp" "$LOG_FILE"
    else
      echo "[!] Файл логов не найден: $LOG_FILE" >> /var/log/nock_monitor.log
    fi

    sleep "$INTERVAL"
  done
}

# === Запуск ===
load_config
echo "✅ Мониторинг блоков \"$SERVER_NAME\" запущен (раз в $((INTERVAL / 3600)) ч)..."
monitor_loop & disown
