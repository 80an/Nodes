#!/bin/bash

# Цвета для вывода
B_GREEN="\e[32m"
B_YELLOW="\e[33m"
B_RED="\e[31m"
NO_COLOR="\e[0m"

# Путь к файлу с переменными окружения
ENV_FILE="$HOME/.validator_env"

# Проверка инициализации pass и наличия сохранённого пароля
if ! command -v pass &> /dev/null || ! pass show validator/keyring_password &> /dev/null; then
  echo -e "\n🔐 Настройка менеджера паролей pass..."
  source <(wget -qO- 'https://raw.githubusercontent.com/80an/Nodes/refs/heads/main/!tools/init-pass.sh')
fi

# Получаем KEYRING_PASSWORD из pass
KEYRING_PASSWORD=$(pass validator/keyring_password)

# Функция загрузки переменных из .env файла
load_env() {
  if [ -f "$ENV_FILE" ]; then
    echo "Загружаем переменные из .env файла..."
    source "$ENV_FILE"
  else
    echo "Файл .env не найден, будет произведен запрос данных у пользователя."
  fi
}

# Функция сохранения переменных в .env файл
save_env() {
  echo "Сохраняем переменные в .env файл..."
  cat > "$ENV_FILE" <<EOF
WALLET_NAME=$WALLET_NAME
WALLET_ADDRESS=$WALLET_ADDRESS
VALIDATOR_ADDRESS=$VALIDATOR_ADDRESS
TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN
TELEGRAM_CHAT_ID=$TELEGRAM_CHAT_ID
EOF
}

# Функция отображения информации и запроса данных
setup_validator() {
  #clear
  echo "========= 🛠️ Настройка валидатора ========="
  echo "Для управления валидатором необходимо ввести следующие данные:"

  # Загружаем переменные из .env, если файл существует
  load_env

  # Проверяем, что KEYRING_PASSWORD не пустой
  if [ -z "$KEYRING_PASSWORD" ]; then
    echo "📥 Загружаем KEYRING_PASSWORD из pass..."
    KEYRING_PASSWORD=$(pass validator/keyring_password)
  fi

  echo "Текущий KEYRING_PASSWORD: $KEYRING_PASSWORD"

  # Проверяем, есть ли данные для WALLET_NAME и WALLET_ADDRESS
  echo "Текущие переменные:"
  echo "WALLET_NAME: $WALLET_NAME"
  echo "WALLET_ADDRESS: $WALLET_ADDRESS"

  # Если переменные пустые, запросим их у пользователя
  if [ -z "$WALLET_NAME" ] || [ -z "$WALLET_ADDRESS" ]; then
    echo "❗ Необходимо ввести данные для кошелька."
    
    # Запрашиваем, что мы хотим ввести: имя или адрес кошелька
    echo "Выберите, что вводить:"
    echo "1) Ввести адрес кошелька"
    echo "2) Ввести имя кошелька"
    read -p "Что выбираете? (1 или 2): " CHOICE

    if [ "$CHOICE" -eq 1 ]; then
      # Вводим адрес кошелька
      read -p "Введите адрес кошелька: " WALLET_ADDRESS
      WALLET_NAME=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_ADDRESS" --output json | jq -r '.name') # Получаем имя кошелька
    elif [ "$CHOICE" -eq 2 ]; then
      # Вводим имя кошелька
      read -p "Введите имя кошелька: " WALLET_NAME
      WALLET_ADDRESS=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_NAME" --bech acc -a)
    else
      echo -e "${B_RED}Неверный выбор. Пожалуйста, выберите 1 или 2.${NO_COLOR}"
      exit 1
    fi
  fi

  # Получаем адрес валидатора
  VALIDATOR_ADDRESS=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_NAME" --bech val -a)

  # Сохраняем переменные в .env файл
  save_env

  # Логируем результат
  echo "✅ Все данные собраны:"
  echo "WALLET_NAME: $WALLET_NAME"
  echo "WALLET_ADDRESS: $WALLET_ADDRESS"
  echo "VALIDATOR_ADDRESS: $VALIDATOR_ADDRESS"
}

# Вызов функции настройки валидатора
setup_validator

# Функция отображения меню
show_menu() {
  #clear
  echo "========= 📋 Меню управления валидатором ========="
  echo "1) 💰 Собрать комиссии и реварды валидатора"
  echo "2) 💸 Собрать реварды со всех кошельков"
  echo "3) 📥 Делегировать валидатору со всех кошельков"
  echo "4) 🗳 Голосование"
  echo "5) 🚪 Выход из тюрьмы (unjail)"
  echo "6) ✅ Включить мониторинг валидатора"
  echo "7) ⛔ Отключить мониторинг валидатора"
  echo "8) ❌ Выход"
  echo "=================================================="
}

# Загружаем переменные из .env, если они есть
load_env

# Если переменные не загружены, выполняем настройку
if [ -z "$KEYRING_PASSWORD" ]; then
  setup_validator
fi

while true; do
  show_menu
  read -p "Выберите действие: " choice

  case $choice in
    1)
      echo "Выполняется сбор комиссий и ревардов валидатора..."
      printf "%s" "$KEYRING_PASSWORD" | 0gchaind tx distribution withdraw-rewards "$VALIDATOR_ADDRESS" \
        --chain-id="zgtendermint_16600-2" \
        --from "$WALLET_NAME" \
        --commission \
        --gas=auto \
        --gas-prices 0.003ua0gi \
        --gas-adjustment=1.4 \
        -y
      ;;
    2)
      echo "Сбор ревардов со всех кошельков..."
      source <(wget -qO- 'https://raw.githubusercontent.com/80an/Nodes/refs/heads/main/0g/all_reward.sh')
      ;;
    3)
      echo "Делегирование валидатору со всех кошельков..."
      source <(wget -qO- 'https://raw.githubusercontent.com/80an/Nodes/refs/heads/main/0g/all_delegation.sh')
      ;;
    4)
      echo "Запуск интерфейса голосования..."
      echo "📮 Поиск активных пропозалов для голосования..."

  # Получаем список активных пропозалов
  proposals=$(0gchaind q gov proposals --status voting_period --output json)

  proposal_count=$(echo "$proposals" | jq '.proposals | length')

  if [ "$proposal_count" -eq 0 ]; then
    echo "❌ Нет активных пропозалов для голосования."
    return 1
  fi

  echo "📋 Список активных пропозалов:"
  for ((i=0; i<proposal_count; i++)); do
    id=$(echo "$proposals" | jq -r ".proposals[$i].id")
    title=$(echo "$proposals" | jq -r ".proposals[$i].content.title")
    echo "  $id) $title"
  done

  read -p "Введите номер пропозала для голосования: " PROPOSAL_ID

  echo "Выберите тип голоса:"
  echo "1) ✅ За"
  echo "2) ❌ Против"
  echo "3) ⛔ Против с вето"
  echo "4) ⚪ Воздержаться"
  read -p "Ваш выбор (1/2/3/4): " VOTE_CHOICE

  case $VOTE_CHOICE in
    1) VOTE_OPTION="yes" ;;
    2) VOTE_OPTION="no" ;;
    3) VOTE_OPTION="no_with_veto" ;;
    4) VOTE_OPTION="abstain" ;;
    *)
      echo "❌ Неверный выбор!"
      return 1
      ;;
  esac

  echo "📤 Отправка голоса '$VOTE_OPTION' по пропозалу #$PROPOSAL_ID..."

  printf "%s" "$KEYRING_PASSWORD" | 0gchaind tx gov vote "$PROPOSAL_ID" "$VOTE_OPTION" \
    --from "$WALLET_NAME" \
    --chain-id="zgtendermint_16600-2" \
    --gas=auto \
    --gas-prices=0.003ua0gi \
    --gas-adjustment=1.4 \
    -y

  echo "✅ Голосование отправлено."
      ;;
    5)
      echo "Выполняется выход из тюрьмы (unjail)..."
      printf "%s" "$KEYRING_PASSWORD" | 0gchaind tx slashing unjail \
        --from "$WALLET_NAME" \
        --chain-id zgtendermint_16600-2 \
        --gas-adjustment 1.5 \
        --gas auto \
        --gas-prices 0.003ua0gi \
        -y
      ;;
    6)
      echo "✅ Запуск мониторинга валидатора..."

  if [[ -z "$TELEGRAM_BOT_TOKEN" || -z "$TELEGRAM_CHAT_ID" ]]; then
    echo -e "${B_YELLOW}⚠️ Telegram Token и Chat ID не заданы.${NO_COLOR}"
    read -p "Введите Telegram Bot Token: " TELEGRAM_BOT_TOKEN
    read -p "Введите Telegram Chat ID: " TELEGRAM_CHAT_ID
    save_env  # Сохраняем новые данные в .env
  else
    echo "Текущий Telegram Bot Token: $TELEGRAM_BOT_TOKEN"
    echo "Текущий Telegram Chat ID: $TELEGRAM_CHAT_ID"
    read -p "❓ Хотите изменить эти данные? (y/N): " change_choice
    if [[ "$change_choice" =~ ^[Yy]$ ]]; then
      read -p "Введите новый Telegram Bot Token: " TELEGRAM_BOT_TOKEN
      read -p "Введите новый Telegram Chat ID: " TELEGRAM_CHAT_ID
      save_env
    fi
  fi

  if [[ -n "$TELEGRAM_BOT_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]]; then
    nohup bash "$HOME/only_monitoring.sh" > /dev/null 2>&1 &
    echo "📡 Мониторинг запущен в фоне."
  else
    echo -e "${B_RED}❌ Мониторинг не был запущен. Telegram данные не указаны.${NO_COLOR}"
  fi
  ;;
    7)
      echo "⛔ Остановка мониторинга валидатора..."
      pkill -f only_monitoring.sh
      ;;
    8)
      echo "Выход..."
      break
      ;;
    *)
      echo "❗ Неверный выбор. Попробуйте снова."
      ;;
  esac
  echo
  read -p "Нажмите Enter для возврата в меню..."
done
