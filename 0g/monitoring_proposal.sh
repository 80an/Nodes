#!/bin/bash

ENV_FILE="$HOME/.validator_env"
PROPOSAL_CACHE="$HOME/.0g_known_proposals"
REMINDER_LOG="$HOME/.0g_proposal_reminders"

# Загрузка переменных окружения
if [ -f "$ENV_FILE" ]; then
  source "$ENV_FILE"
else
  echo "❌ Не найден файл переменных $ENV_FILE"
  exit 1
fi

send_telegram_alert() {
  local message="$1"
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d parse_mode="HTML" \
    -d text="$message" > /dev/null
}

# Форматирование времени в МСК
to_msk() {
  local iso_time="$1"
  date -d "$iso_time +3 hours" +"%d-%m-%Y %H:%M (МСК)"
}

mkdir -p "$(dirname "$PROPOSAL_CACHE")"
touch "$PROPOSAL_CACHE"
touch "$REMINDER_LOG"

# Стартовая проверка: есть ли активные голосования
initial_proposals=$(0gchaind q gov proposals --output json | jq -c '.proposals[]')
current_found=false
latest_id=""
latest_end=""

echo "$initial_proposals" | while IFS= read -r prop; do
  id=$(echo "$prop" | jq -r '.id')
  status=$(echo "$prop" | jq -r '.status')

  if [ "$status" == "PROPOSAL_STATUS_VOTING_PERIOD" ]; then
    current_found=true
    voting_end=$(echo "$prop" | jq -r '.voting_end_time')
    msk_time=$(to_msk "$voting_end")

    # Универсально достаём title
    title=$(echo "$prop" | jq -r '.title // .content.title // .content["@type"] // "Без названия"')

    # Универсально достаём описание
    description=$(echo "$prop" | jq -r '.description // .summary // .content.description // empty')
    if [[ -z "$description" || "$description" == "null" ]]; then
      description=$(echo "$prop" | jq -r '.content.changes[]? | "\(.subspace): \(.key) => \(.value)"' 2>/dev/null | head -c 400)
      [[ -z "$description" ]] && description="Описание отсутствует"
    fi
    description=$(echo "$description" | head -c 400)

    start_msg=$(cat <<EOF
<b>📢 Текущее голосование №$id</b>

<b>📝 Название:</b> $title
<b>📄 Описание:</b> $description

<b>📅 До:</b> <code>$msk_time</code>
<b>📌 Статус:</b> $status

🗳 Не забудьте проголосовать!
EOF
)
    send_telegram_alert "$start_msg"
  fi

  if [[ -z "$latest_id" || "$id" -gt "$latest_id" ]]; then
    latest_id="$id"
    latest_end=$(echo "$prop" | jq -r '.voting_end_time')
  fi
done

if [ "$current_found" = false ]; then
  formatted_end=$(to_msk "$latest_end")
  msg=$(cat <<EOF
<b>📊 Текущих голосований нет.</b>

Последнее голосование: №<b>$latest_id</b>
<b>📅 Завершено:</b> <code>$formatted_end</code>

📉 Голосовать не нужно, но следите за новыми пропозалами, Бот вам в помощь!
EOF
)
  send_telegram_alert "$msg"
fi

# Основной цикл
while true; do
  proposals=$(0gchaind q gov proposals --output json | jq -c '.proposals[]')

  echo "$proposals" | while IFS= read -r prop; do
    id=$(echo "$prop" | jq -r '.id')
    status=$(echo "$prop" | jq -r '.status')
    voting_end=$(echo "$prop" | jq -r '.voting_end_time')
    deadline_ts=$(date -d "$voting_end" +%s 2>/dev/null)
    msk_time=$(to_msk "$voting_end")

    # Универсально достаём title
    title=$(echo "$prop" | jq -r '.title // .content.title // .content["@type"] // "Без названия"')

    # Универсально достаём описание
    description=$(echo "$prop" | jq -r '.description // .summary // .content.description // empty')
    if [[ -z "$description" || "$description" == "null" ]]; then
      description=$(echo "$prop" | jq -r '.content.changes[]? | "\(.subspace): \(.key) => \(.value)"' 2>/dev/null | head -c 400)
      [[ -z "$description" ]] && description="Описание отсутствует"
    fi
    description=$(echo "$description" | head -c 400)

    # Новое предложение
    if ! grep -q "^$id$" "$PROPOSAL_CACHE"; then
      echo "$id" >> "$PROPOSAL_CACHE"
      message=$(cat <<EOF
<b>📢 Новый пропозал №$id</b>

<b>📝 Название:</b> $title
<b>📄 Описание:</b> $description

<b>📅 До:</b> <code>$msk_time</code>
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

<b>📅 До:</b> <code>$msk_time</code>
<b>📌 Статус:</b> $status

$msg_time
EOF
)
        send_telegram_alert "$reminder_msg"
        echo "$label" >> "$REMINDER_LOG"
      fi
    done
  done

  sleep 300
done

