#!/bin/bash

# === Цвета ===
B_GREEN="\e[32m"
B_YELLOW="\e[33m"
B_RED="\e[31m"
NO_COLOR="\e[0m"

# === Загрузка переменных ===
ENV_FILE="$HOME/.validator_config/env"
if [ -f "$ENV_FILE" ]; then
  set -o allexport
  source "$ENV_FILE"
  set +o allexport
else
  echo -e "${B_RED}❌ Не найден файл с переменными: $ENV_FILE${NO_COLOR}"
  exit 1
fi

# === Проверка обязательных переменных ===
if [ -z "$VALIDATOR_ADDRESS" ] || [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ] || [ -z "$RPC_URL" ]; then
  echo -e "${B_RED}❌ Не все обязательные переменные заданы в $ENV_FILE${NO_COLOR}"
  exit 1
fi

# === Telegram уведомление ===
send_telegram_alert() {
  local message="$1"
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
       -d chat_id="$TELEGRAM_CHAT_ID" \
       -d parse_mode="HTML" \
       -d text="$message" > /dev/null
}

# === Получение данных ===
get_stake() {
  0gchaind q staking validator "$VALIDATOR_ADDRESS" --output json | jq -r '.tokens | tonumber'
}

get_missed_blocks() {
  0gchaind q slashing signing-info $(0gchaind tendermint show-validator) --output json | jq -r '.missed_blocks_counter'
}

get_jailed_status() {
  0gchaind q staking validator "$VALIDATOR_ADDRESS" --output json | jq -r '.jailed'
}

get_latest_height() {
  curl -s "$RPC_URL/status" | jq -r '.result.sync_info.latest_block_height'
}

get_local_height() {
  0gchaind status 2>/dev/null | jq -r '.SyncInfo.latest_block_height'
}

# === Стартовое уведомление ===
initial_jailed=$(get_jailed_status)
initial_stake=$(get_stake)
initial_missed=$(get_missed_blocks)
initial_pid=$$

message=$(cat <<EOF
<b>📡 Мониторинг валидатора запущен</b>
🔢 PID: $initial_pid
🚦 Jail: $initial_jailed
💰 Стейк: $((initial_stake / 1000000))
📉 Пропущено блоков: $initial_missed
EOF
)
send_telegram_alert "$message"

# === Цикл мониторинга ===
last_jail_status="$initial_jailed"
last_stake="$initial_stake"
last_jail_alert_ts=0

while true; do
  jailed=$(get_jailed_status)
  stake=$(get_stake)
  missed=$(get_missed_blocks)
  now_ts=$(date +%s)

  # === Jail ===
  if [ "$jailed" = "true" ]; then
    if [ $((now_ts - last_jail_alert_ts)) -ge 10800 ]; then
      local_height=$(get_local_height)
      remote_height=$(get_latest_height)
      lag=$((remote_height - local_height))
      [ "$lag" -lt 0 ] && lag="❌ Ошибка RPC, отставание < 0"

      message=$(cat <<EOF
⛔️ <b>Валидатор в тюрьме!</b>
📉 Отставание от RPC: $lag
EOF
)
      send_telegram_alert "$message"
      last_jail_alert_ts=$now_ts
    fi
  elif [ "$last_jail_status" = "true" ] && [ "$jailed" = "false" ]; then
    stake_diff=$((stake - last_stake))
    stake_rounded=$((stake / 1000000))
    sign=$( [ "$stake_diff" -gt 0 ] && echo "+$((stake_diff / 1000000)) 🟢⬆️" || echo "$((stake_diff / 1000000)) 🔴⬇️" )
    lag=$(( $(get_latest_height) - $(get_local_height) ))

    message=$(cat <<EOF
✅ <b>Валидатор вышел из тюрьмы!</b>
💰 Изменение стейка: $stake_rounded ($sign)
📉 Отставание: $lag
EOF
)
    send_telegram_alert "$message"
    last_jail_alert_ts=0
  fi

  last_jail_status="$jailed"
  last_stake="$stake"

  # === Проверка корректности данных ===
  if [[ ! "$missed" =~ ^[0-9]+$ ]]; then
    send_telegram_alert "<b>❗️ Ошибка получения missed_blocks_counter</b>%0AВозможно, RPC не отвечает."
  fi

  sleep 300
done
