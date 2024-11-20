#!/bin/bash

# Получение имени ключа
name_key=$(artelad keys list -n)
if [ -z "$name_key" ]; then
  echo "Ошибка: имя ключа не найдено."
  exit 1
fi
echo "Имя ключа: $name_key"

# Получение адреса кошелька
wallet_address=$(artelad keys list | grep "address:" | awk -F': ' '{print $2}')
if [ -z "$wallet_address" ]; then
  echo "Ошибка: адрес кошелька не найден."
  exit 1
fi
echo "Адрес кошелька: $wallet_address"

# Вывод наград валидатора
validator_address=$(artelad keys show "$name_key" --bech val -a)
if [ -z "$validator_address" ]; then
  echo "Ошибка: адрес валидатора не найден."
  exit 1
fi
echo "Адрес валидатора: $validator_address"

echo "Вывод наград валидатора..."
artelad tx distribution withdraw-rewards "$validator_address" \
  --chain-id="artela_11822-1" \
  --from "$name_key" \
  --commission \
  --gas=auto \
  --gas-adjustment=1.4 \
  -y

# Проверка баланса
balance_info=$(artelad q bank balances "$wallet_address")
if [ -z "$balance_info" ]; then
  echo "Ошибка: не удалось получить информацию о балансе."
  exit 1
fi
echo "Информация о балансе: $balance_info"

# Извлечение количества токенов (в uart)
amount=$(echo "$balance_info" | grep -B 1 "uart" | grep "amount" | awk '{print $3}' | tr -d '"')
if [ -z "$amount" ]; then
  echo "Ошибка: не удалось определить сумму для делегации."
  exit 1
fi
echo "Количество токенов для делегации: $amount"

# Делегирование
echo "Начало делегации..."
artelad tx staking delegate "$validator_address" "${amount}uart" \
  --from "$name_key" \
  --chain-id artela_11822-1 \
  --gas-prices 0.1uart \
  --gas-adjustment 1.5 \
  --gas auto \
  -y
