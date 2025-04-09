#!/bin/bash

ENV_FILE="$HOME/.validator_env"

# Проверяем наличие .env файла
if [ ! -f "$ENV_FILE" ]; then
  echo "❌ Файл .env ($ENV_FILE) не найден. Пожалуйста, сначала настройте валидатора."
  exit 1
fi

# Загружаем переменные
source "$ENV_FILE"

# Проверка необходимых переменных
if [ -z "$KEYRING_PASSWORD" ] || [ -z "$VALIDATOR_ADDRESS" ]; then
  echo "❌ Не найдены необходимые переменные: KEYRING_PASSWORD или VALIDATOR_ADDRESS"
  exit 1
fi

# Получаем список кошельков
wallet_names=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys list | grep "name:" | awk '{print $2}')

# Обрабатываем каждый кошелек
for wallet_name in $wallet_names
do
    balance_info=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind q bank balances $(0gchaind keys show "$wallet_name" -a))
    amount=$(echo "$balance_info" | grep -B 1 "ua0gi" | grep "amount" | awk '{print $3}' | tr -d '"')

    if [ -n "$amount" ] && [ "$amount" -ge 100 ] 2>/dev/null; then
        echo "🪙 Кошелек: $wallet_name, Баланс: ${amount} ua0gi"
        printf "%s" "$KEYRING_PASSWORD" | 0gchaind tx staking delegate "$VALIDATOR_ADDRESS" "${amount}ua0gi" \
          --from "$wallet_name" \
          --gas=auto \
          --gas-prices 0.003ua0gi \
          --gas-adjustment=1.4 \
          -y
        sleep $((RANDOM % 81 + 20))
    fi
done
