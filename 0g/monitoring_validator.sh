#!/bin/bash

# Цвета для вывода
B_GREEN="\e[32m"
B_YELLOW="\e[33m"
B_RED="\e[31m"
NO_COLOR="\e[0m"

# Функция округления до миллионов
round_millions() {
  echo "$(( $1 / 1000000 ))"
}

# Файл для сохранения предыдущего стейка
STAKE_FILE="$HOME/.0G_validator_stake"

# Функция отправки сообщений в Telegram
send_telegram_alert() {
  local message="$1"
  echo "Отправка сообщения в Telegram: $message"
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d parse_mode="HTML" \
    -d text="$message" > /dev/null
}

# Тестовое сообщение при запуске
initial_stake=$(0gchaind q staking validator "$VALIDATOR_ADDRESS" --output json | jq -r '.tokens')
initial_stake_rounded=$(round_millions "$initial_stake")
initial_pid=$$
initial_jailed=$(0gchaind q staking validator "$VALIDATOR_ADDRESS" --output json | jq -r .jailed)
initial_missed=$(0gchaind q slashing signing-info $(0gchaind tendermint show-validator) --output json | jq -r .missed_blocks_counter)

message=$(cat <<EOF
<b>📡 Мониторинг запущен (PID: $initial_pid)</b><br><br>
🚦 Jail: $initial_jailed<br>
💰 Стейк: ${initial_stake_rounded}<br>
📉 Пропущено блоков: $initial_missed
EOF
)
send_telegram_alert "$message"

# Бесконечный цикл
while true; do
  echo "Запуск цикла мониторинга..."

  # Получение текущего стейка
  current_stake=$(0gchaind q staking validator "$VALIDATOR_ADDRESS" --output json | jq -r '.tokens')
  rounded_stake=$(round_millions "$current_stake")

  # Проверка изменений стейка
  if [ -f "$STAKE_FILE" ]; then
    prev_stake=$(cat "$STAKE_FILE")
    if [ "$rounded_stake" -ne "$prev_stake" ]; then
      change=$(( rounded_stake - prev_stake ))
      if [ "$change" -gt 0 ]; then
        sign="+${change} 🟢⬆️"
      else
        sign="${change#-} 🔴⬇️"
      fi
      send_telegram_alert "💰 Изменение стейка: ${rounded_stake} (${sign})"
      echo "$rounded_stake" > "$STAKE_FILE"
    fi
  else
    echo "$rounded_stake" > "$STAKE_FILE"
  fi

  # Получение jailed статуса
  jailed=$(0gchaind q staking validator "$VALIDATOR_ADDRESS" --output json | jq -r .jailed)
  
  # Получение пропущенных блоков
  missed=$(0gchaind q slashing signing-info $(0gchaind tendermint show-validator) --output json | jq -r .missed_blocks_counter)

  # Отправка сообщений, если есть изменения
  if [ "$jailed" = "true" ]; then
    send_telegram_alert "⛔️ Валидатор в тюрьме!\nНеобходимо принять меры!\n📉 Отставание от RPC: $missed"
  fi

  # Пауза 5 минут
  sleep 300
done
