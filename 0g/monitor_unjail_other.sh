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

# Получаем имя кошелька
WALLET_NAME=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys list --output json | jq -r '.[0].name')

# Выводим значение WALLET_NAME для отладки
echo "Wallet name: $WALLET_NAME"

if [ -z "$WALLET_NAME" ]; then
  echo -e "${B_RED}Error: Wallet name is empty. Please check your keyring password.${NO_COLOR}"
  exit 1
fi

# Получаем адрес валидатора
VALIDATOR_ADDRESS=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_NAME" --bech val -a)

# Выводим адрес валидатора для отладки
echo "Validator address: $VALIDATOR_ADDRESS"

if [ -z "$VALIDATOR_ADDRESS" ]; then
  echo -e "${B_RED}Error: Validator address is empty. Please check your keyring password or wallet name.${NO_COLOR}"
  exit 1
fi

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

# Функция записи логов
log_message() {
  local message="$1"
  echo "$(date) - $message" >> "$HOME/$PROJECT_DIR/logs.txt"
}

# Функция проверки высоты блоков и перезапуска ноды при отставании
check_blocks() {
  RPC_PORT=$(grep -m 1 -oP '^laddr = "\K[^"]+' "$HOME/$PROJECT_DIR/config/config.toml" | cut -d ':' -f 3)
  while true; do
    NODE_HEIGHT=$(curl -s localhost:$RPC_PORT/status | jq -r '.result.sync_info.latest_block_height')
    RPC_HEIGHT=$(curl -s https://og-testnet-rpc.itrocket.net/status | jq -r '.result.sync_info.latest_block_height')

    if ! [[ "$NODE_HEIGHT" =~ ^[0-9]+$ ]] || ! [[ "$RPC_HEIGHT" =~ ^[0-9]+$ ]]; then
      echo -e "${B_RED}Error: Invalid block height data. Retrying...${NO_COLOR}"
      sleep 5
      continue
    fi

    BLOCKS_LEFT=$((RPC_HEIGHT - NODE_HEIGHT))
    if [ "$BLOCKS_LEFT" -lt 0 ]; then
      BLOCKS_LEFT=0
    fi

    echo -e "Node Height: ${B_GREEN}$NODE_HEIGHT${NO_COLOR} | RPC Height: ${B_YELLOW}$RPC_HEIGHT${NO_COLOR} | Blocks Left: ${B_RED}$BLOCKS_LEFT${NO_COLOR}"

    if [ "$BLOCKS_LEFT" -gt 5 ]; then
      echo -e "${B_RED}Difference greater than 5. Restarting node...${NO_COLOR}"
      log_message "Difference greater than 5 blocks. Restarting node..."
      send_telegram_alert "⚠️ Node is behind by $BLOCKS_LEFT blocks. Restarting..."
      sudo systemctl restart ogd
      sleep 30
    fi

    sleep 5
  done
}

check_blocks &
wait
