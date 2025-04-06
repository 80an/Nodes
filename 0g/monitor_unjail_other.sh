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
    for url in "${RPC_URLS[@]}"; do
      height=$(curl -s "$url/status" | jq -r '.result.sync_info.latest_block_height')
      if [[ "$height" =~ ^[0-9]+$ ]]; then
        if [ "$url" != "$CURRENT_RPC" ]; then
          CURRENT_RPC="$url"
          echo -e "${B_YELLOW}🔄 Используется новый RPC: $CURRENT_RPC${NO_COLOR}"
          send_telegram_alert "ℹ️ Переключение на доступный RPC: $CURRENT_RPC"
        fi
        echo "$height"
        return
      else
        echo -e "${B_YELLOW}⚠️ RPC не ответил: $url${NO_COLOR}"
      fi
    done
    echo "0"
  }

  while true; do
    NODE_HEIGHT=$(curl -s localhost:$RPC_PORT/status | jq -r '.result.sync_info.latest_block_height')
    RPC_HEIGHT=$(get_rpc_height)

    if ! [[ "$NODE_HEIGHT" =~ ^[0-9]+$ ]] || [ "$RPC_HEIGHT" -eq 0 ]; then
      echo -e "${B_RED}❌ Ошибка получения высот. Повтор через 5 секунд...${NO_COLOR}"
      sleep 5
      continue
    fi

    BLOCKS_LEFT=$((RPC_HEIGHT - NODE_HEIGHT))
    [ "$BLOCKS_LEFT" -lt 0 ] && BLOCKS_LEFT=0

    echo -e "Node Height: ${B_GREEN}$NODE_HEIGHT${NO_COLOR} | RPC Height: ${B_YELLOW}$RPC_HEIGHT${NO_COLOR} | Blocks Left: ${B_RED}$BLOCKS_LEFT${NO_COLOR}"

    if [ "$BLOCKS_LEFT" -gt 5 ]; then
      echo -e "${B_RED}⚠️ Разница больше 5 блоков. Перезапуск...${NO_COLOR}"
      send_telegram_alert "⚠️ Node is behind by $BLOCKS_LEFT blocks (using RPC: $CURRENT_RPC). Restarting..."
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
