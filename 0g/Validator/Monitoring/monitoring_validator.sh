#!/bin/bash

# === Цвета для ошибок в терминале (используется только при отладке) ===
B_RED="\e[31m"
NO_COLOR="\e[0m"

# === Загрузка переменных окружения из ~/.validator_config/env ===
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
if [ -z "$VALIDATOR_ADDRESS" ] || [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
  echo -e "${B_RED}❌ Не все обязательные переменные заданы в $ENV_FILE${NO_COLOR}"
  exit 1
fi

# === Определение локального RPC-порта из config.toml ===
PROJECT_DIR=".0gchain"
RPC_PORT=$(grep -m 1 -oP '^laddr = "\K[^"]+' "$HOME/$PROJECT_DIR/config/config.toml" | cut -d ':' -f 3)
LOCAL_RPC="http://localhost:$RPC_PORT"

# === Список удалённых RPC — сначала noders, затем itrocket ===
REMOTE_RPC_1="https://og-t-rpc.noders.services"
REMOTE_RPC_2="https://og-testnet-rpc.itrocket.net"

# === Функция выбора рабочего RPC (возвращает первый, который отвечает) ===
select_working_rpc() {
  for url in "$REMOTE_RPC_1" "$REMOTE_RPC_2"; do
    if curl -s --max-time 3 "$url/status" | grep -q '"latest_block_height"'; then
      echo "$url"
      return
    fi
  done
  echo ""
}

# === Выбор рабочего удалённого RPC ===
REMOTE_RPC=$(select_working_rpc)
if [ -z "$REMOTE_RPC" ]; then
  # Если ни один RPC не отвечает — отправка сообщения и выход
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
       -d chat_id="$TELEGRAM_CHAT_ID" \
       -d parse_mode="HTML" \
       -d text="❌ Нет доступного RPC. Мониторинг не запущен." > /dev/null
  exit 1
else
  # Уведомление об использовании конкретного RPC
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
       -d chat_id="$TELEGRAM_CHAT_ID" \
       -d parse_mode="HTML" \
       -d text="📡 Используется RPC: <code>$REMOTE_RPC</code>" > /dev/null
fi

# === Универсальная функция отправки сообщений в Telegram ===
send_telegram_alert() {
  local message="$1"
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
       -d chat_id="$TELEGRAM_CHAT_ID" \
       -d parse_mode="HTML" \
       -d text="$message" > /dev/null
}

# === Функции получения данных о валидаторе ===
get_stake() {
  0gchaind q staking validator "$VALIDATOR_ADDRESS" --output json | jq -r '.tokens | tonumber'
}

get_missed_blocks() {
  0gchaind q slashing signing-info $(0gchaind tendermint show-validator) --output json | jq -r '.missed_blocks_counter'
}

get_jailed_status() {
  0gchaind q staking validator "$VALIDATOR_ADDRESS" --output json | jq -r '.jailed'
}

# === Получение высот из локального и удалённого RPC ===
get_local_height() {
  curl -s "$LOCAL_RPC/status" | jq -r '.result.sync_info.latest_block_height'
}

get_remote_height() {
  curl -s "$REMOTE_RPC/status" | jq -r '.result.sync_info.latest_block_height'
}

# === Стартовое уведомление при запуске мониторинга ===
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

# === Инициализация переменных для отслеживания изменений ===
last_jail_status="$initial_jailed"
last_stake="$initial_stake"
last_jail_alert_ts=0
zero_lag_counter=0

# === Главный цикл мониторинга ===
while true; do
  jailed=$(get_jailed_status)
  stake=$(get_stake)
  missed=$(get_missed_blocks)
  now_ts=$(date +%s)

  local_height=$(get_local_height)
  remote_height=$(get_remote_height)

  # === Проверка лагов ===
  if [[ "$local_height" =~ ^[0-9]+$ ]] && [[ "$remote_height" =~ ^[0-9]+$ ]]; then
    lag=$((remote_height - local_height))

    if [ "$lag" -lt 0 ]; then
      send_telegram_alert "⚠️ Отставание стало отрицательным (lag=$lag). Возможна ошибка RPC или узла."
    elif [ "$lag" -eq 0 ]; then
      zero_lag_counter=$((zero_lag_counter + 1))
      if [ "$zero_lag_counter" -ge 3 ]; then
        send_telegram_alert "❗️ Node и RPC на одной высоте ($remote_height), но блоки не растут!"
        zero_lag_counter=0
      fi
    else
      zero_lag_counter=0
    fi
  else
    # === Ошибка получения высот ===
    send_telegram_alert "❌ Ошибка получения высот. local=$local_height, remote=$remote_height"
  fi

  # === Проверка Jail ===
  if [ "$jailed" = "true" ]; then
    if [ $((now_ts - last_jail_alert_ts)) -ge 10800 ]; then
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
    # === Валидатор вышел из тюрьмы ===
    stake_diff=$((stake - last_stake))
    stake_rounded=$((stake / 1000000))
    sign=$( [ "$stake_diff" -gt 0 ] && echo "+$((stake_diff / 1000000)) 🟢⬆️" || echo "$((stake_diff / 1000000)) 🔴⬇️" )

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

  # === Проверка получения счетчика пропущенных блоков ===
  if [[ ! "$missed" =~ ^[0-9]+$ ]]; then
    send_telegram_alert "<b>❗️ Ошибка получения missed_blocks_counter</b>%0AВозможно, RPC не отвечает."
  fi

  sleep 300
done
