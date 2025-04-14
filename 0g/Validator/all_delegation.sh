#!/bin/bash

# Проверка, что необходимые переменные заданы
if [ -z "$KEYRING_PASSWORD" ] || [ -z "$VALIDATOR_ADDRESS" ]; then
  echo "❌ Отсутствуют ключевые переменные (KEYRING_PASSWORD или VALIDATOR_ADDRESS)."
  echo "➡️ Сначала запустите start.sh и setup_validator.sh"
  exit 1
fi

# Получаем список кошельков
wallet_names=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys list | grep "name:" | awk '{print $2}')

# Обрабатываем каждый кошелек
for WALLET_NAME in $wallet_names
do
    balance_info=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind q bank balances $(0gchaind keys show "$WALLET_NAME" -a))
    amount=$(echo "$balance_info" | grep -B 1 "ua0gi" | grep "amount" | awk '{print $2}' | tr -d '"')

    if [ -n "$amount" ] && [ "$amount" -ge 100 ] 2>/dev/null; then
        echo "🪙 Кошелек: $wallet_name, Баланс: ${amount} ua0gi"
        printf "%s" "$KEYRING_PASSWORD" | 0gchaind tx staking delegate "$VALIDATOR_ADDRESS" "${amount}ua0gi" \
          --from "$WALLET_NAME" \
          --gas=auto \
          --gas-prices 0.003ua0gi \
          --gas-adjustment=1.4 \
          -y

        # Пауза от 20 до 100 секунд
        delay=$((RANDOM % 81 + 20))
        echo "⏳ Пауза $delay секунд перед следующим кошельком..."
        sleep "$delay"
     else
    echo "⚠️ Недостаточный баланс или ошибка для $WALLET_NAME. Пропускаем..."
  fi
done

echo "✅ Все делегации успешно выполнены."
