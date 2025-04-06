#!/bin/bash

PROJECT_NAME="0G"
PROJECT_DIR=".0gchain"

# Цвета для вывода
B_GREEN="\e[32m"
B_YELLOW="\e[33m"
B_RED="\e[31m"
NO_COLOR="\e[0m"

# Запрашиваем пароль от keyring
echo
read -s -p "Enter keyring password: " KEYRING_PASSWORD
echo

# Запрашиваем, что мы хотим ввести: имя или адрес кошелька
echo "Выберете, что вводить:"
echo "1) Ввести адрес кошелька"
echo "2) Ввести имя кошелька"
read -p "Что выбираете? (1 или 2): " CHOICE

if [ "$CHOICE" -eq 1 ]; then
  # Вводим адрес кошелька
  read -p "Ввести адрес кошелька: " WALLET_ADDRESS
  WALLET_NAME=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_ADDRESS" --output json | jq -r '.name') # Получаем имя кошелька
elif [ "$CHOICE" -eq 2 ]; then
  # Вводим имя кошелька
  read -p "Ввести имя кошелька: " WALLET_NAME
  WALLET_ADDRESS=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_NAME" --bech acc -a)
else
  echo -e "${B_RED}Invalid choice. Please select 1 or 2.${NO_COLOR}"
  exit 1
fi

# Получаем адрес валидатора
VALIDATOR_ADDRESS=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_NAME" --bech val -a)

# Выводим информацию о кошельке и валидаторе
echo -e "${B_GREEN}Wallet Name: ${NO_COLOR}$WALLET_NAME"
echo -e "${B_YELLOW}Wallet Address: ${NO_COLOR}$WALLET_ADDRESS"
echo -e "${B_RED}Validator Address: ${NO_COLOR}$VALIDATOR_ADDRESS"

# Получаем адрес Telegram-бота и Chat ID
read -p "Enter your Telegram Bot Token: " TELEGRAM_BOT_TOKEN
read -p "Enter your Telegram Chat ID: " TELEGRAM_CHAT_ID

# Функция отправки уведомлений в Telegram
send_telegram_alert() {
  local message="$1"
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
       -d chat_id="$TELEGRAM_CHAT_ID" \
       -d text="$message"
}

# Функция проверки высоты блоков и перезапуска ноды при отставании
check_blocks() {
  RPC_PORT=$(grep -m 1 -oP '^laddr = "\K[^"]+' "$HOME/$PROJECT_DIR/config/config.toml" | cut -d ':' -f 3)

  # Список RPC
  RPC_URLS=("https://rpc.0g.noders.services" "https://0g-rpc.stavr.tech")
  CURRENT_RPC=""

  # Функция получения высоты из первого доступного RPC
  get_rpc_height() {
  local now_ts=$(date +%s)
  local error_rpc_ts_file="/tmp/rpc_error_timestamp"

  for url in "${RPC_URLS[@]}"; do
    response=$(curl -s "$url/status")
    height=$(echo "$response" | jq -r '.result.sync_info.latest_block_height' 2>/dev/null)

    if [[ "$height" =~ ^[0-9]+$ ]]; then
      if [ "$url" != "$CURRENT_RPC" ]; then
        CURRENT_RPC="$url"
        echo -e "${B_YELLOW}🔄 Используется новый RPC: $CURRENT_RPC${NO_COLOR}" >&2
        send_telegram_alert "ℹ️ Переключение на доступный RPC: $CURRENT_RPC"
      fi
      echo "$height"
      return 0
    else
      echo -e "${B_YELLOW}⚠️ RPC не ответил: $url${NO_COLOR}" >&2
    fi
  done

  # Если ни один RPC не сработал
  echo "0"

  # Отправка алерта, если прошло больше 10 минут
  if [ -f "$error_rpc_ts_file" ]; then
    last_sent_ts=$(cat "$error_rpc_ts_file")
  else
    last_sent_ts=0
  fi

  if [ $((now_ts - last_sent_ts)) -ge 600 ]; then
    send_telegram_alert "🚫 Все RPC недоступны! Ни один из RPC не отвечает."
    echo "$now_ts" > "$error_rpc_ts_file"
  fi

  return 1
}

# Функция проверки статуса валидатора и автоматического unjail
check_validator() {
  while true; do
    jailed_status=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind q staking validator "$VALIDATOR_ADDRESS" --output json | jq -r '.jailed')
    echo "Validator jailed status: $jailed_status"
    if [ "$jailed_status" = "true" ]; then
      echo -e "${B_RED}Validator is jailed! Executing unjail command...${NO_COLOR}"
      send_telegram_alert "🚨 Validator is jailed! Attempting unjail..."
      printf "%s" "$KEYRING_PASSWORD" | 0gchaind tx slashing unjail \
        --from "$WALLET_NAME" \
        --chain-id zgtendermint_16600-2 \
        --gas-adjustment 1.7 \
        --gas auto \
        --gas-prices 0.003ua0gi \
        -y
    fi
    sleep 300
  done
}

check_blocks &
check_validator &
wait
