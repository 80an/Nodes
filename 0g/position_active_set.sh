# Получаем количество валидаторов (уже получено)
total_validators=$(0gchaind q staking validators --count-total --output json | jq -r '.pagination.total')

# Инициализация переменных
page=1
limit=200
validators=""

# Пагинация для получения валидаторов
while true; do
  response=$(0gchaind q staking validators --limit "$limit" --page "$page" --output json)
  new_validators=$(echo "$response" | jq -r '.validators[] | select(.status == "BOND_STATUS_BONDED") | {operator_address: .operator_address, tokens: .tokens}')
  validators+=$'\n'"$new_validators"
  
  # Получаем ключ для следующей страницы
  next_key=$(echo "$response" | jq -r '.pagination.next_key')
  
  # Если следующий ключ равен null, значит все данные получены
  if [ "$next_key" == "null" ]; then
    break
  fi
  
  page=$((page + 1))
done

# Находим свой валидатор
VALIDATOR_ADDRESS="0gvaloper1cr7m6pvvht650hwtnwwv25ssrsazdxmefdx2nf"

# Получаем все валидаторы в формате "адрес: стейк"
validators_list=$(echo "$validators" | jq -r '.operator_address + ": " + .tokens')

# Сортируем по стейку (чтобы числа правильно сортировались)
sorted_validators=$(echo "$validators_list" | sort -t: -k2 -n -r)

# Ищем позицию вашего валидатора
position=1
for validator in $sorted_validators; do
  address=$(echo "$validator" | cut -d: -f1)
  if [ "$address" == "$VALIDATOR_ADDRESS" ]; then
    break
  fi
  position=$((position + 1))
done

# Выводим позицию
echo "Позиция вашего валидатора в активном сете: $position"

