#!/bin/bash

B_GREEN="\e[32m"
B_YELLOW="\e[33m"
B_RED="\e[31m"
NO_COLOR="\e[0m"

ENV_FILE="$HOME/.validator_env"
STAKE_FILE="$HOME/.0G_validator_stake"
JAIL_NOTICE_FILE="$HOME/.0G_validator_jail_notice"

# Загрузка переменных
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

# Получаем информацию
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

# === Первая отправка ===
initial_jailed=$(get_jailed_status)
initial_stake=$(get_stake)
initial_missed=$(get_missed_blocks)
initial_pid=$$

message=$(cat <<EOF
<b>📡 Мониторинг запущен</b>
🔢 PID процесса: $initial_pid

🚦 Jail: $initial_jailed
💰 Стейк: $((initial_stake / 1000000))
📉 Пропущено блоков: $initial_missed

EOF
)
send_telegram_alert "$message"

# === Главный цикл ===
last_jail_status="$initial_jailed"
last_stake="$initial_stake"
last_jail_alert_ts=0

while true; do
  jailed=$(get_jailed_status)
  stake=$(get_stake)
  missed=$(get_missed_blocks)
  now_ts=$(date +%s)

  # === Проверка Jail ===
  if [ "$jailed" = "true" ]; then
    # Показываем каждые 3 часа
    if [ $((now_ts - last_jail_alert_ts)) -ge 10800 ]; then
      local_height=$(get_local_height)
      remote_height=$(get_latest_height)
      lag=$((remote_height - local_height))
      [ "$lag" -lt 0 ] && lag="❌ Ошибка RPC, отставание < 0"

      message=$(cat <<EOF
⛔️ <b>Валидатор в тюрьме!</b>
Необходимо принять меры!
📉 Отставание от RPC: $lag
EOF
)
      send_telegram_alert "$message"
      last_jail_alert_ts=$now_ts
    fi
  elif [ "$last_jail_status" = "true" ] && [ "$jailed" = "false" ]; then
    local_height=$(get_local_height)
    remote_height=$(get_latest_height)
    lag=$((remote_height - local_height))
    message=$(cat <<EOF
✅ <b>Валидатор вышел из тюрьмы!</b>
📉 Отставание: $lag
EOF
)
    send_telegram_alert "$message"
    last_jail_alert_ts=0
  fi
  last_jail_status="$jailed"

  # === Проверка изменения стейка ===
  if [ "$stake" -ne "$last_stake" ]; then
    stake_diff=$((stake - last_stake))
    stake_rounded=$((stake / 1000000))
    if [ "$stake_diff" -gt 0 ]; then
      sign="+$((stake_diff / 1000000)) 🟢⬆️"
    else
      sign="$((stake_diff / 1000000)) 🔴⬇️"
    fi
    message=$(cat <<EOF
💰 Изменение стейка: $stake_rounded ($sign)
EOF
)
    send_telegram_alert "$message"
    last_stake="$stake"
  fi

  # === Предупреждение о некорректных блоках ===
  if [[ ! "$missed" =~ ^[0-9]+$ ]]; then
    message=$(cat <<EOF
❗️ Ошибка получения missed_blocks_counter — возможно, RPC не отвечает.
EOF
)
    send_telegram_alert "$message"
  fi

  sleep 300
done

