#!/bin/bash

# Цвета для вывода
B_GREEN="\e[32m"
B_YELLOW="\e[33m"
B_RED="\e[31m"
NO_COLOR="\e[0m"

ENV_FILE="$HOME/.validator_env"
RANK_FILE="$HOME/.0g_validator_rank"

# Загрузка переменных окружения
if [ -f "$ENV_FILE" ]; then
  source "$ENV_FILE"
else
  echo "❌ Не найден файл переменных $ENV_FILE"
  exit 1
fi

# Отправка сообщений в Telegram
send_telegram_alert() {
  local message="$1"
  echo "Отправка сообщения в Telegram: $message"  # Добавлено для отладки
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d parse_mode="HTML" \
    -d text="$message" > /dev/null
}

# Тестовое сообщение
send_telegram_alert "Тестовое сообщение от скрипта. Проверка связи."

# Бесконечный цикл
while true; do
  echo "Запуск цикла мониторинга..."  # Отладка начала цикла

  # Получение jailed статуса
  jailed=$(0gchaind q staking validator "$VALIDATOR_ADDRESS" --output json | jq -r .jailed)
  echo "Jailed статус: $jailed"  # Отладка получения jailed статуса

  # Получение пропущенных блоков
  missed=$(0gchaind q slashing signing-info $(0gchaind tendermint show-validator) --output json | jq -r .missed_blocks_counter)
  echo "Пропущено блоков: $missed"  # Отладка получения missed блоков

  # Получаем список активных валидаторов
  active_validators=$(0gchaind q staking validators --output json --limit 3000 | jq -r '.validators[] | select(.status=="BOND_STATUS_BONDED") | .operator_address')
  echo "Активные валидаторы: $active_validators"  # Отладка списка валидаторов

  rank=1
  found=0

  while IFS= read -r val; do
    if [ "$val" = "$VALIDATOR_ADDRESS" ]; then
      found=1
      break
    fi
    rank=$((rank + 1))
  done <<< "$active_validators"

  rank_info=""
  changed=0  # флаг изменений

  if [ "$found" -eq 1 ]; then
    echo "Валидатор найден. Ранг: $rank"
    rank_info="🔢 Место в активном сете: #$rank"
    if [ -f "$RANK_FILE" ]; then
      prev_rank=$(cat "$RANK_FILE")
      echo "Предыдущий ранг: $prev_rank"  # Добавьте вывод для отладки
      if [ "$rank" -ne "$prev_rank" ]; then
        changed=1
        echo "Ранг изменился, обновляем файл"  # Отладка изменения ранга
        if [ "$rank" -lt "$prev_rank" ]; then
          send_telegram_alert "📈 Валидатор поднялся: с #$prev_rank на #$rank"
        else
          send_telegram_alert "📉 Валидатор опустился: с #$prev_rank на #$rank"
        fi
      fi
    else
      changed=1
      echo "Создаем новый файл для ранга"  # Отладка создания нового файла
    fi
    echo "$rank" > "$RANK_FILE"
  else
    rank_info="⚠️ Валидатор не в активном сете"
    if [ -f "$RANK_FILE" ]; then
      changed=1
      send_telegram_alert "⚠️ Валидатор выбыл из активного сета!"
      rm "$RANK_FILE"
    fi
  fi

  # Отладка, что условие для отправки сообщения выполняется
  echo "Изменился ли статус или jail: $changed, jailed: $jailed"

  # Отправка основного статуса, только если были изменения или jail
  if [ "$changed" -eq 1 ] || [ "$jailed" = "true" ]; then
    message=$(cat <<EOF
<b>🧾 Статус валидатора</b>

$rank_info
🚦 Jail: $jailed
📉 Пропущено блоков: $missed
EOF
)
    echo "Отправка сообщения о статусе валидатора: $message"  # Отладка отправки сообщения
    send_telegram_alert "$message"
  fi

  sleep 300  # Пауза 5 минут (можешь изменить по желанию)

done
