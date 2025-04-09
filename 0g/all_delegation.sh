#!/bin/bash

# Загрузка переменных из .env
source "$HOME/.validator_env"

wallet_names=$(echo "$KEYRING_PASSWORD" | 0gchaind keys list | grep "name:" | awk '{print $2}')

for wallet_name in $wallet_names
do
    balance_info=$(printf "%s" echo "$KEYRING_PASSWORD" | 0gchaind q bank balances $(0gchaind keys show "$wallet_name" -a))
    amount=$(echo "$balance_info" | grep -B 1 "ua0gi" | grep "amount" | awk '{print $2}' | tr -d '"')

    if [ -n "$amount" ] && [ "$amount" -ge 100 ] 2>/dev/null; then
        echo "Кошелек: $wallet_name, Баланс: ${amount} ua0gi"
        echo "$KEYRING_PASSWORD" | 0gchaind tx staking delegate "$VALIDATOR_ADDRESS" "${amount}ua0gi" \
          --from "$wallet_name" \
          --gas=auto \
          --gas-prices 0.003ua0gi \
          --gas-adjustment=1.4 \
          -y
        sleep $((RANDOM % 81 + 20))
    fi
done
