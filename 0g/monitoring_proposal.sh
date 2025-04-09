#!/bin/bash

ENV_FILE="$HOME/.0g_monitor_env"
PROPOSAL_CACHE="$HOME/.0g_known_proposals"
REMINDER_LOG="$HOME/.0g_proposal_reminders"

# Загрузка .env
if [ -f "$ENV_FILE" ]; then
  source "$ENV_FILE"
else
  echo "❌ Не найден файл настроек $ENV_FILE"
  exit 1
fi

send_telegram_alert() {
  local message="$1"
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d parse_mode="HTML" \
    -d text="$message" > /dev/null
}

mkdir -p "$(dirname "$PROPOSAL_CACHE")"
touch "$PROPOSAL_CACHE"
touch "$REMINDER_LOG"

while true; do
  proposals=$(0gchaind q gov proposals --output json | jq -c '.proposals[]')

  echo "$proposals" | while IFS= read -r prop; do
    id=$(echo "$prop" | jq -r '.id')
    title=$(echo "$prop" | jq -r '.content.title')
    description=$(echo "$prop" | jq -r '.content.description' | head -c 400)  # Обрезаем длинное описание
    status=$(echo "$prop" | jq -r '.status')
    voting_end=$(echo "$prop" | jq -r '.voting_end_time')
    deadline_ts=$(date -d "$voting_end" +%s 2>/dev/null)

    # Новое предложение
    if ! grep -q "^$id$" "$PROPOSAL_CACHE"; then
      echo "$id" >> "$PROPOSAL_CACHE"
      message=$(cat <<EOF
<b>📢 Новый пропозал №$id</b>

<b>📝 Название:</b> $title
<b>📄 Описание:</b> $description

<b>📅 Голосование до:</b> <code>$voting_end</code>
<b>📌 Статус:</b> $status

🗳 Не забудьте проголосовать!
EOF
)
      send_telegram_alert "$message"
    fi

    # Напоминания
    now_ts=$(date +%s)
    for interval in 86400 10800 3600; do
      label="$id-$interval"
      if [ $((deadline_ts - now_ts)) -le $interval ] && ! grep -q "$label" "$REMINDER_LOG"; then
        case $interval in
          86400) msg_time="⏰ Остался 1 день до окончания голосования";;
          10800) msg_time="⏰ Осталось 3 часа до окончания голосования";;
          3600)  msg_time="⏰ Остался 1 час до окончания голосования";;
        esac
        reminder_msg=$(cat <<EOF
<b>🔔 Напоминание о голосовании №$id</b>

<b>📝 Название:</b> $title
<b>📄 Описание:</b> $description

<b>📅 До:</b> <code>$voting_end</code>
<b>📌 Статус:</b> $status

$msg_time
EOF
)
        send_telegram_alert "$reminder_msg"
        echo "$label" >> "$REMINDER_LOG"
      fi
    done
  done

  sleep 300  # каждые 5 минут
done
