#!/bin/bash

# Цвета
B_GREEN="\e[32m"
B_YELLOW="\e[33m"
B_RED="\e[31m"
NO_COLOR="\e[0m"

read -s -p "Введите пароль от keyring: " KEYRING_PASSWORD
echo
read -p "Введите имя кошелька (валидатора): " WALLET_NAME
read -p "Введите chain-id (например, zgtendermint_16600-2): " CHAIN_ID
read -p "Введите минимальную сумму комиссии (например, 0.005ua0gi): " GAS_PRICES

VALIDATOR_ADDRESS=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_NAME" --bech val -a)

menu() {
  echo
  echo "========= 🛠 Меню управления валидатором 0G ========="
  echo "1) 🔓 Выход из тюрьмы (Unjail)"
  echo "2) 💸 Сбор ревардов и комиссии с валидатора"
  echo "3) 🪙 Сбор ревардов со всех кошельков"
  echo "4) ➕ Делегирование во валидатора со всех кошельков"
  echo "5) 🔍 Проверка статуса валидатора"
  echo "6) 🗳 Голосование по пропозалу"
  echo "7) ❌ Выход"
  echo "======================================================"
}

while true; do
  menu
  read -p "Выберите действие: " choice
  case $choice in
    1)
      echo -e "${B_GREEN}Выход из тюрьмы...${NO_COLOR}"
      printf "%s" "$KEYRING_PASSWORD" | 0gchaind tx slashing unjail --from "$WALLET_NAME" --chain-id "$CHAIN_ID" --gas auto --gas-adjustment 1.5 --gas-prices "$GAS_PRICES" -y
      ;;
    2)
      echo -e "${B_GREEN}Сбор наград и комиссии с валидатора...${NO_COLOR}"
      printf "%s" "$KEYRING_PASSWORD" | 0gchaind tx distribution withdraw-rewards "$VALIDATOR_ADDRESS" --from "$WALLET_NAME" --commission --chain-id "$CHAIN_ID" --gas auto --gas-adjustment 1.5 --gas-prices "$GAS_PRICES" -y
      ;;
    3)
      echo -e "${B_GREEN}Сбор ревардов со всех кошельков...${NO_COLOR}"
      for delegator in $(0gchaind q staking delegations-to "$VALIDATOR_ADDRESS" --output json | jq -r '.[].delegation.delegator_address'); do
        printf "%s" "$KEYRING_PASSWORD" | 0gchaind tx distribution withdraw-rewards "$VALIDATOR_ADDRESS" --from "$delegator" --chain-id "$CHAIN_ID" --gas auto --gas-adjustment 1.5 --gas-prices "$GAS_PRICES" -y
      done
      ;;
    4)
      echo -e "${B_GREEN}Делегирование со всех кошельков во валидатора...${NO_COLOR}"
      for delegator in $(0gchaind keys list --output json | jq -r '.[].name'); do
        balance=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind q bank balances "$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys show "$delegator" --bech acc -a)" --output json | jq -r '.balances[] | select(.denom=="ua0gi") | .amount')
        amount=$((balance - 10000)) # оставляем 0.01 токена на комиссии
        if (( amount > 10000 )); then
          printf "%s" "$KEYRING_PASSWORD" | 0gchaind tx staking delegate "$VALIDATOR_ADDRESS" "${amount}ua0gi" --from "$delegator" --chain-id "$CHAIN_ID" --gas auto --gas-adjustment 1.5 --gas-prices "$GAS_PRICES" -y
        fi
      done
      ;;
    5)
      echo -e "${B_GREEN}Проверка статуса валидатора...${NO_COLOR}"
      0gchaind q staking validator "$VALIDATOR_ADDRESS" --output json | jq '.description.moniker, .jailed, .status'
      ;;
    6)
      read -p "Введите ID пропозала: " PROPOSAL_ID
      read -p "Ваш голос (yes / no / no_with_veto / abstain): " VOTE
      printf "%s" "$KEYRING_PASSWORD" | 0gchaind tx gov vote "$PROPOSAL_ID" "$VOTE" --from "$WALLET_NAME" --chain-id "$CHAIN_ID" --gas auto --gas-adjustment 1.5 --gas-prices "$GAS_PRICES" -y
      ;;
    7)
      echo -e "${B_YELLOW}Выход...${NO_COLOR}"
      break
      ;;
    *)
      echo -e "${B_RED}Неверный выбор. Повторите попытку.${NO_COLOR}"
      ;;
  esac
done
