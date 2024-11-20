#!/bin/bash

# Получаем имя ключа
name_key=$(artelad keys list -n)

# Получаем адрес валидатора и аккаунта
validator_address=$(artelad keys show $name_key --bech val -a)
account_address=$(artelad keys show $name_key --bech acc -a)

# Команда для вывода комиссий
artelad tx distribution withdraw-rewards $validator_address --chain-id="artela_11822-1" --from $name_key --commission --gas=auto --gas-adjustment=1.4 -y

# Пауза в 3 секунды, чтобы гарантировать обработку транзакции
sleep 3

# Получаем информацию о балансе
balance_info=$(artelad q bank balances $account_address)

# Извлекаем сумму для делегирования
amount=$(echo "$balance_info" | grep -B 1 "uart" | grep "amount" | awk '{print $3}' | tr -d '"')

# Убедимся, что сумма извлечена корректно
if [[ -z "$amount" ]]; then
  echo "Ошибка: Не удалось извлечь сумму для делегирования."
  exit 1
fi

# Команда для делегирования
artelad tx staking delegate $validator_address "${amount}uart" --from $name_key --chain-id artela_11822-1 --gas-prices 0.1uart --gas-adjustment=1.5 --gas auto -y
