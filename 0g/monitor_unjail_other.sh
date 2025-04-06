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

# Функция получения высоты блоков из RPC
get_rpc_height() {
  response=$(curl -s https://og-t-rpc.noders.services/status)
  rpc_height=$(echo "$response" | jq -r '.result.sync_info.latest_block_height')

  if [[ "$rpc_height" =~ ^[0-9]+$ ]]; then
    echo "$rpc_height"
  else
    echo -e "${B_RED}⚠️ Error: Invalid RPC height data. Retrying...${NO_COLOR}"
    return 1
  fi
}

# Функция получения высоты блоков с ноды
get_node_height() {
  RPC_PORT=$(grep -m 1 -oP '^laddr = "\K[^"]+' "$HOME/$PROJECT_DIR/config/config.toml" | cut -d ':' -f 3)
  node_height=$(curl -s localhost:$RPC_PORT/status | jq -r '.result.sync_info.latest_block_height')

  if [[ "$node_height" =~ ^[0-9]+$ ]]; then
    echo "$node_height"
  else
    echo -e "${B_RED}⚠️ Error: Invalid Node height data. Retrying...${NO_COLOR}"
    return 1
  fi
}

# Функция проверки высоты блоков и перезапуска ноды при отставании
check_blocks() {
  while true; do
    # Получаем высоту блоков ноды и RPC
    NODE_HEIGHT=$(get_node_height)
    RPC_HEIGHT=$(get_rpc_height)

    if [[ "$NODE_HEIGHT" =~ ^[0-9]+$ ]] && [[ "$RPC_HEIGHT" =~ ^[0-9]+$ ]]; then
      # Вычисляем разницу между высотами блоков
      BLOCKS_LEFT=$((RPC_HEIGHT - NODE_HEIGHT))
      if [ "$BLOCKS_LEFT" -lt 0 ]; then
        BLOCKS_LEFT=0
      fi

      echo -e "Node Height: ${B_GREEN}$NODE_HEIGHT${NO_COLOR} | RPC Height: ${B_YELLOW}$RPC_HEIGHT${NO_COLOR} | Blocks Left: ${B_RED}$BLOCKS_LEFT${NO_COLOR}"

      # Если разница больше 5 блоков, перезапускаем ноду
      if [ "$BLOCKS_LEFT" -gt 5 ]; then
        echo -e "${B_RED}Difference greater than 5. Restarting node...${NO_COLOR}"
        sudo systemctl restart ogd
        # Ждём 30 секунд после перезапуска, чтобы нода успела восстановиться
        sleep 30
      fi
    else
      echo -e "${B_RED}⚠️ Invalid height data. Retrying...${NO_COLOR}"
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
        --gas-adjustment 2.0 \
        --gas auto \
        --gas-prices 0.005ua0gi \
        -y
    fi
    # Ждём 5 минут (300 секунд) до следующей проверки
    sleep 300
  done
}

check_blocks & 
check_validator & 
wait
