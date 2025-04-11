#!/bin/bash

# Цвета для вывода
B_GREEN="\e[32m"
B_YELLOW="\e[33m"
B_RED="\e[31m"
NO_COLOR="\e[0m"

ENV_FILE="$HOME/.validator_env"
RANK_FILE="$HOME/.0G_validator_rank"

# Загрузка переменных окружения
if [ -f "$ENV_FILE" ]; then
  source "$ENV_FILE"
else
  echo "❌ Не найден файл переменных $ENV_FILE"
  exit 1
fi

# Отправка сообщений в Telegram
send_telegram_alert() {
  local message="$1"
  echo "Отправка сообщения в Telegram: $message"  # Для отладки
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d parse_mode="HTML" \
    -d text="$message" > /dev/null
}

# Тестовое сообщение
send_telegram_alert "Тестовое сообщение от скрипта. Проверка связи."

# Бесконечный цикл
while true; do
  echo "Запуск цикла мониторинга..."  # Для отладки

  # Получение jailed статуса
  jailed=$(0gchaind q staking validator "$VALIDATOR_ADDRESS" --output json | jq -r .jailed)
  echo "Jailed статус: $jailed"  # Для отладки получения jailed статуса

  # Получение пропущенных блоков
  missed=$(0gchaind q slashing signing-info $(0gchaind tendermint show-validator) --output json | jq -r .missed_blocks_counter)
  echo "Пропущено блоков: $missed"  # Для отладки получения missed блоков

  # Получаем текущий стейк
  stake=$(0gchaind q staking validator "$VALIDATOR_ADDRESS" --output json | jq -r '.validator.description.moniker' )
  echo "Текущий стейк: $stake" # Для отладки

  # Получение размера стейка и округление до миллиона
  stake_rounded=$(echo "scale=0; $stake / 1000000" | bc)
  stake_msg="💰 Стейк: ${stake_rounded}"

  # Проверка на "в тюрьме"
  if [ "$jailed" = "true" ]; then
    message="⛔️ Валидатор в тюрьме!\nНеобходимо принять меры!\n📉 Отставание от RPC: $missed"
    send_telegram_alert "$message"
  fi

  # Проверка изменений в стейке
  # Сравниваем текущий стейк с предыдущим
  if [ -f "$RANK_FILE" ]; then
    prev_stake=$(cat "$RANK_FILE")
    if [ "$stake_rounded" -gt "$prev_stake" ]; then
      change_msg="💰 Изменение стейка: $stake_rounded (+$((stake_rounded - prev_stake)) 🟢⬆️)"
    elif [ "$stake_rounded" -lt "$prev_stake" ]; then
      change_msg="💰 Изменение стейка: $stake_rounded (-$((prev_stake - stake_rounded)) 🔴⬇️)"
    else
      change_msg=""
    fi
  else
    change_msg=""
  fi

  # Если изменения в стейке, отправить сообщение
  if [ -n "$change_msg" ]; then
    send_telegram_alert "$change_msg"
  fi

  # Обновляем файл с текущим стейком
  echo "$stake_rounded" > "$RANK_FILE"

  # Отправка текущего статуса
  status_message="🔢 PID процесса: $$\n$stake_msg\n🚦 Jail: $jailed\n📉 Пропущено блоков: $missed"
  send_telegram_alert "$status_message"

  # Пауза 5 минут
  sleep 300

done
