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
echo "Choose the way to specify wallet:"
echo "1) Enter wallet address"
echo "2) Enter wallet name"
read -p "Enter your choice (1 or 2): " CHOICE

if [ "$CHOICE" -eq 1 ]; then
  # Вводим адрес кошелька
  read -p "Enter wallet address: " WALLET_ADDRESS
  WALLET_NAME=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_ADDRESS" --bech val -a)
elif [ "$CHOICE" -eq 2 ]; then
  # Вводим имя кошелька
  read -p "Enter wallet name: " WALLET_NAME
  WALLET_ADDRESS=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_NAME" --bech val -a)
else
  echo -e "${B_RED}Invalid choice. Please select 1 or 2.${NO_COLOR}"
  exit 1
fi

# Получаем адрес валидатора
VALIDATOR_ADDRESS="$WALLET_ADDRESS"

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
      send_telegram_alert "⚠️ Node is behind by $BLOCKS_LEFT blocks. Restarting..."
      sudo systemctl restart ogd
      sleep 30
    fi

    sleep 5
  done
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
