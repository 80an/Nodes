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

# Функция отправки уведомлений в Telegram
send_telegram_alert() {
  local message="$1"
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
       -d chat_id="$TELEGRAM_CHAT_ID" \
       -d parse_mode="HTML" \
       -d text="$message" > /dev/null
}

# Функция перевода UTC -> МСК
to_msk() {
  local input="$1"
  TZ="Europe/Moscow" date -d "$input" '+%d-%m-%Y %H:%M (МСК)'
}

# Проверка кэша
if [ ! -f "$PROPOSAL_CACHE" ]; then
  touch "$PROPOSAL_CACHE"
fi
if [ ! -f "$REMINDER_LOG" ]; then
  touch "$REMINDER_LOG"
fi

# ======================= ПЕРВОНАЧАЛЬНЫЙ ЗАПУСК ========================
proposals=$(0gchaind q gov proposals --output json | jq '.proposals // []')

current_open_found=false
last_id=0
last_status=""
last_end=""

for row in $(echo "$proposals" | jq -r '.[] | @base64'); do
  _jq() {
    echo "$row" | base64 --decode | jq -r "$1"
  }

  id=$(_jq '.id')
  status=$(_jq '.status')
  voting_end=$(_jq '.voting_end_time')

  if [ "$status" == "PROPOSAL_STATUS_VOTING_PERIOD" ]; then
    current_open_found=true

    title=$(_jq '.title // .content.title // .content["@type"] // "Без названия"')
    description=$(_jq '.description // .summary // .content.description // empty')
    if [[ -z "$description" || "$description" == "null" ]]; then
      description=$(_jq '.content.changes[]? | "\(.subspace): \(.key) => \(.value)"' | head -c 400)
      [[ -z "$description" ]] && description="Описание отсутствует"
    fi
    description=$(echo "$description" | head -c 400)

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

  if [ "$id" -gt "$last_id" ]; then
    last_id=$id
    last_status=$status
    last_end=$voting_end
  fi
done

if [ "$current_open_found" = false ]; then
  formatted_end=$(to_msk "$last_end")
  msg=$(cat <<EOF
<b>📊 Текущих голосований нет.</b>

Последнее предложение: №<b>$last_id</b>
<b>📌 Статус:</b> $last_status
<b>📅 Завершено:</b> <code>$formatted_end</code>

📉 Голосовать сейчас не нужно, но следите за новыми пропозалами!
EOF
)
  send_telegram_alert "$msg"
fi
# ======================================================================

# Инициализация
init_alerts_file

# Бесконечный цикл проверки
while true; do
  proposals=$(0gchaind q gov proposals --status voting_period --output json | jq -c '.proposals[]?')

  now_ts=$(date +%s)
  alerts=$(cat "$VOTING_ALERTED_FILE")

  echo "$proposals" | while IFS= read -r prop; do
    id=$(echo "$prop" | jq -r '.id')
    voting_end=$(echo "$prop" | jq -r '.voting_end_time')
    voting_end_ts=$(date -d "$voting_end" +%s)

    title=$(echo "$prop" | jq -r '.title // .content.title // .content["@type"] // "Без названия"')
    description=$(echo "$prop" | jq -r '.description // .summary // .content.description // empty')
    if [[ -z "$description" || "$description" == "null" ]]; then
      description=$(echo "$prop" | jq -r '.content.changes[]? | "\(.subspace): \(.key) => \(.value)"' 2>/dev/null | head -c 400)
      [[ -z "$description" ]] && description="Описание отсутствует"
    fi
    description=$(echo "$description" | head -c 400)

    for delta in 86400 10800 3600; do
      key="id_${id}_$delta"
      already_sent=$(echo "$alerts" | jq -r --arg key "$key" '.[$key] // empty')

      if [ -z "$already_sent" ] && [ $((voting_end_ts - now_ts)) -le $delta ] && [ $((voting_end_ts - now_ts)) -gt 0 ]; then
        msk_time=$(to_msk "$voting_end")
        msg=$(cat <<EOF
<b>🔔 Напоминание о голосовании №$id</b>

<b>📝 Название:</b> $title
<b>📄 Описание:</b> $description

<b>📅 До:</b> <code>$msk_time</code>
<b>⏳ Осталось:</b> $(($delta / 3600)) ч

🗳 Не забудьте проголосовать!
EOF
)
        send_telegram_alert "$msg"
        alerts=$(echo "$alerts" | jq --arg key "$key" '.[$key] = true')
        echo "$alerts" > "$VOTING_ALERTED_FILE"
      fi
    done
  done

  sleep 300
done
