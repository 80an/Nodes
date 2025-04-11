#!/bin/bash

ENV_FILE="$HOME/.0g_monitor_env"
PROPOSAL_CACHE="$HOME/.0g_known_proposals"
REMINDER_LOG="$HOME/.0g_proposal_reminders"

# Загрузка переменных окружения
ENV_FILE="$HOME/.validator_env"
if [ -f "$ENV_FILE" ]; then
  source "$ENV_FILE"
else
  echo "❌ Не найден файл переменных $ENV_FILE"
  exit 1
fi

# Функция для отправки уведомлений в Telegram
send_telegram_alert() {
  local message="$1"
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d parse_mode="HTML" \
    -d text="$message" > /dev/null
}

# Функция для форматирования даты в Московское время
format_date() {
  date -d "$1" '+%d-%m-%Y %H:%M (МСК)'
}

mkdir -p "$(dirname "$PROPOSAL_CACHE")"
touch "$PROPOSAL_CACHE"
touch "$REMINDER_LOG"

# Получаем все предложения
proposals=$(0gchaind q gov proposals --output json | jq -c '.proposals[]')

# Проверяем, есть ли активные голосования
active_proposals=false
message=""

echo "$proposals" | while IFS= read -r prop; do
  id=$(echo "$prop" | jq -r '.id')
  title=$(echo "$prop" | jq -r '.content.title')
  description=$(echo "$prop" | jq -r '.content.description' | head -c 400)  # Обрезаем длинное описание
  status=$(echo "$prop" | jq -r '.status')
  voting_end=$(echo "$prop" | jq -r '.voting_end_time')
  deadline_ts=$(date -d "$voting_end" +%s 2>/dev/null)

  # Проверяем, если голосование активно
  if [ "$status" == "VotingPeriod" ]; then
    active_proposals=true
    message+=$(cat <<EOF
<b>📢 Новый пропозал №$id</b>

<b>📝 Название:</b> $title
<b>📄 Описание:</b> $description

<b>📅 Голосование до:</b> <code>$(format_date "$voting_end")</code>
<b>📌 Статус:</b> $status

🗳 Не забудьте проголосовать!
EOF
)
  fi
done

if [ "$active_proposals" = true ]; then
  send_telegram_alert "$message"
else
  last_proposal_id=$(echo "$proposals" | jq -r '.[0].id')
  last_proposal_end=$(echo "$proposals" | jq -r '.[0].content.voting_end_time')
  last_proposal_end_formatted=$(format_date "$last_proposal_end")
  message=$(cat <<EOF
<b>📊 Текущих голосований нет.</b>

<b>Последнее голосование:</b> №$last_proposal_id
<b>📅 Завершено:</b> <code>$last_proposal_end_formatted</code>

📉 Проголосовать не нужно, но следите за новыми предложениями!
EOF
)
  send_telegram_alert "$message"
fi

# Напоминания для активных голосований
while true; do
  echo "$proposals" | while IFS= read -r prop; do
    id=$(echo "$prop" | jq -r '.id')
    title=$(echo "$prop" | jq -r '.content.title')
    description=$(echo "$prop" | jq -r '.content.description' | head -c 400)  # Обрезаем длинное описание
    status=$(echo "$prop" | jq -r '.status')
    voting_end=$(echo "$prop" | jq -r '.voting_end_time')
    deadline_ts=$(date -d "$voting_end" +%s 2>/dev/null)

    # Напоминания только для голосующих предложений
    if [ "$status" == "VotingPeriod" ]; then
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

<b>📅 До:</b> <code>$(format_date "$voting_end")</code>
<b>📌 Статус:</b> $status

$msg_time
EOF
)
          send_telegram_alert "$reminder_msg"
          echo "$label" >> "$REMINDER_LOG"
        fi
      done
    fi
  done

  sleep 300  # каждые 5 минут
done
