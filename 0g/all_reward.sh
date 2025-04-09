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

# Проходим по каждому кошельку
for wallet_name in $wallet_names; do
  echo "💸 Выводим реварды для $wallet_name"
  printf "%s" "$KEYRING_PASSWORD" | 0gchaind tx distribution withdraw-rewards "$VALIDATOR_ADDRESS" \
    --chain-id="zgtendermint_16600-2" \
    --from "$wallet_name" \
    --gas=auto \
    --gas-prices 0.003ua0gi \
    --gas-adjustment=1.4 \
    -y
  
  # Пауза от 20 до 100 секунд
  delay=$((RANDOM % 81 + 20))
  echo "⏳ Пауза $delay секунд перед следующим кошельком..."
  sleep "$delay"
done

echo "✅ Все реварды успешно собраны."

