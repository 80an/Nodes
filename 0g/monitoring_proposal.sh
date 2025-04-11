#!/bin/bash

# Конфиг
CHAIN_ID="zgtendermint_16600-2"
DENOM="ua0gi"
WALLET_NAME="wallet"
VOTING_ALERTED_FILE="/tmp/voting_alerts.json"
TELEGRAM_BOT_TOKEN=$(pass show telegram/bot_token)
TELEGRAM_CHAT_ID=$(pass show telegram/chat_id)

# Отправка сообщения в Telegram
send_telegram_alert() {
  local message="$1"
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d parse_mode="HTML" \
    -d text="$message" > /dev/null
}

# Перевод UTC времени в МСК
to_msk() {
  local input="$1"
  TZ="Europe/Moscow" date -d "$input" '+%d-%m-%Y %H:%M (МСК)'
}

# Создание файла с алертами, если его нет
init_alerts_file() {
  if [ ! -f "$VOTING_ALERTED_FILE" ]; then
    echo "{}" > "$VOTING_ALERTED_FILE"
  fi
}

# ==================== СТАРТОВАЯ ПРОВЕРКА =======================
initial_proposals=$(0gchaind q gov proposals --output json | jq -c '.proposals[]')
current_found=false
latest_id=""
latest_status=""
latest_end=""

echo "$initial_proposals" | while IFS= read -r prop; do
  id=$(echo "$prop" | jq -r '.id')
  status=$(echo "$prop" | jq -r '.status')

  if [ "$status" == "PROPOSAL_STATUS_VOTING_PERIOD" ]; then
    current_found=true
    voting_end=$(echo "$prop" | jq -r '.voting_end_time')
    msk_time=$(to_msk "$voting_end")

    title=$(echo "$prop" | jq -r '.title // .content.title // .content["@type"] // "Без названия"')
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
    latest_status="$status"
    latest_end=$(echo "$prop" | jq -r '.voting_end_time')
  fi
done

if [ "$current_found" = false ]; then
  formatted_end=$(to_msk "$latest_end")
  msg=$(cat <<EOF
<b>📊 Текущих голосований нет.</b>

Последнее предложение: №<b>$latest_id</b>
<b>📌 Статус:</b> $latest_status
<b>📅 Завершено:</b> <code>$formatted_end</code>

📉 Голосовать сейчас не нужно, но следите за новыми пропозалами!
EOF
)
  send_telegram_alert "$msg"
fi
# ===============================================================

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
