#!/bin/bash

# Проверка, что необходимые переменные заданы
if [ -z "$KEYRING_PASSWORD" ] || [ -z "$VALIDATOR_ADDRESS" ]; then
  echo "❌ Отсутствуют ключевые переменные (KEYRING_PASSWORD или VALIDATOR_ADDRESS)."
  echo "➡️ Сначала запустите start.sh и setup_validator.sh"
  exit 1
fi

# Получаем список кошельков
wallet_names=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys list | grep "name:" | awk '{print $2}')

# Проходим по каждому кошельку
for WALLET_NAME in $wallet_names; do
  echo "💸 Выводим реварды для $WALLET_NAME"
  printf "%s" "$KEYRING_PASSWORD" | 0gchaind tx distribution withdraw-rewards "$VALIDATOR_ADDRESS" \
    --chain-id="zgtendermint_16600-2" \
    --from "$WALLET_NAME" \
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
