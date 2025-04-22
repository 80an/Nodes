#!/bin/bash

# === Цвета для ошибок в терминале (используется только при отладке) ===
B_RED="\e[31m"
NO_COLOR="\e[0m"

# === Загрузка переменных окружения из ~/.validator_config/env ===
ENV_FILE="$HOME/.validator_config/env"
PROPOSAL_CACHE="$HOME/.0g_known_proposals"
REMINDER_LOG="$HOME/.0g_proposal_reminders"
if [ -f "$ENV_FILE" ]; then
  set -o allexport
  source "$ENV_FILE"
  set +o allexport
else
  echo -e "${B_RED}❌ Не найден файл с переменными: $ENV_FILE${NO_COLOR}"
  exit 1
fi

# === Проверка обязательных переменных ===
if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
  echo -e "${B_RED}❌ Не все обязательные переменные заданы в $ENV_FILE${NO_COLOR}"
  exit 1
fi

# === Утилиты ===

send_telegram_alert() {
  local message="$1"
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d parse_mode="HTML" \
    -d text="$message" > /dev/null
}

to_msk() {
  local iso_time="$1"
  date -d "$iso_time +3 hours" +"%d-%m-%Y %H:%M (МСК)"
}

extract_title() {
  echo "$1" | jq -r '.title // .content.title // .content["@type"] // "Без названия"'
}

extract_description() {
  local desc=$(echo "$1" | jq -r '.description // .summary // .content.description // empty')
  if [[ -z "$desc" || "$desc" == "null" ]]; then
    desc=$(echo "$1" | jq -r '.content.changes[]? | "\(.subspace): \(.key) => \(.value)"' 2>/dev/null | head -c 400)
    [[ -z "$desc" ]] && desc="Описание отсутствует"
  fi
  echo "$desc" | head -c 400
}

mkdir -p "$(dirname "$PROPOSAL_CACHE")"
touch "$PROPOSAL_CACHE" "$REMINDER_LOG"

# === Стартовая проверка ===

proposals_json=$(0gchaind q gov proposals --output json)
current_proposals=$(echo "$proposals_json" | jq -c '.proposals[]')
found_current=false
latest_id=""
latest_end=""

echo "$current_proposals" | while IFS= read -r prop; do
  id=$(echo "$prop" | jq -r '.id')
  status=$(echo "$prop" | jq -r '.status')

  if [ "$status" == "PROPOSAL_STATUS_VOTING_PERIOD" ]; then
    found_current=true
    voting_end=$(echo "$prop" | jq -r '.voting_end_time')
    title=$(extract_title "$prop")
    description=$(extract_description "$prop")
    msk_time=$(to_msk "$voting_end")

    msg=$(cat <<EOF
<b>📢 Текущее голосование №$id</b>

<b>📝 Название:</b> $title
<b>📄 Описание:</b> $description

<b>📅 До:</b> <code>$msk_time</code>
<b>📌 Статус:</b> $status

🗳 Не забудьте проголосовать!
EOF
)
    send_telegram_alert "$msg"
  fi

  if [[ -z "$latest_id" || "$id" -gt "$latest_id" ]]; then
    latest_id="$id"
    latest_end=$(echo "$prop" | jq -r '.voting_end_time')
  fi
done

if [ "$found_current" = false ]; then
  msk_end=$(to_msk "$latest_end")
  msg=$(cat <<EOF
<b>📊 Текущих голосований нет.</b>

Последнее голосование: №<b>$latest_id</b>
<b>📅 Завершено:</b> <code>$msk_end</code>

📉 Проголосовать не нужно, но следите за новыми предложениями!
EOF
)
  send_telegram_alert "$msg"
fi

# === Основной цикл мониторинга ===
while true; do
  proposals=$(0gchaind q gov proposals --output json | jq -c '.proposals[]')

  echo "$proposals" | while IFS= read -r prop; do
    id=$(echo "$prop" | jq -r '.id')
    status=$(echo "$prop" | jq -r '.status')
    voting_end=$(echo "$prop" | jq -r '.voting_end_time')
    deadline_ts=$(date -d "$voting_end" +%s)
    now_ts=$(date +%s)
    title=$(extract_title "$prop")
    description=$(extract_description "$prop")
    msk_time=$(to_msk "$voting_end")

    # Новое предложение
    if ! grep -q "^$id$" "$PROPOSAL_CACHE"; then
      echo "$id" >> "$PROPOSAL_CACHE"
      msg=$(cat <<EOF
<b>📢 Новый пропозал №$id</b>

<b>📝 Название:</b> $title
<b>📄 Описание:</b> $description

<b>📅 До:</b> <code>$msk_time</code>
<b>📌 Статус:</b> $status

🗳 Не забудьте проголосовать!
EOF
)
      send_telegram_alert "$msg"
    fi

    # Напоминания
    for interval in 86400 10800 3600; do
      label="$id-$interval"
      if [ $((deadline_ts - now_ts)) -le $interval ] && ! grep -q "$label" "$REMINDER_LOG"; then
        case $interval in
          86400) msg_time="⏰ Остался 1 день до окончания голосования";;
          10800) msg_time="⏰ Осталось 3 часа до окончания голосования";;
          3600)  msg_time="⏰ Остался 1 час до окончания голосования";;
        esac

        msg=$(cat <<EOF
<b>🔔 Напоминание о голосовании №$id</b>

<b>📝 Название:</b> $title
<b>📄 Описание:</b> $description

<b>📅 До:</b> <code>$msk_time</code>
<b>📌 Статус:</b> $status

$msg_time
EOF
)
        send_telegram_alert "$msg"
        echo "$label" >> "$REMINDER_LOG"
      fi
    done
  done

  sleep 300
done
