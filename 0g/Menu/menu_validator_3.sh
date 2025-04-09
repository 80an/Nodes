#!/bin/bash

# Цвета для вывода
B_GREEN="\e[32m"
B_YELLOW="\e[33m"
B_RED="\e[31m"
NO_COLOR="\e[0m"

# Путь к файлу с переменными окружения
ENV_FILE="$HOME/.validator_env"

# Функция загрузки переменных из .env файла
load_env() {
  if [ -f "$ENV_FILE" ]; then
    echo "Загружаем переменные из .env файла..."
    # Чтение переменных из .env
    source "$ENV_FILE"
  fi
}

# Функция сохранения переменных в .env файл
save_env() {
  echo "Сохраняем переменные в .env файл..."
  cat > "$ENV_FILE" <<EOF
KEYRING_PASSWORD=$KEYRING_PASSWORD
WALLET_NAME=$WALLET_NAME
WALLET_ADDRESS=$WALLET_ADDRESS
VALIDATOR_ADDRESS=$VALIDATOR_ADDRESS
TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN
TELEGRAM_CHAT_ID=$TELEGRAM_CHAT_ID
EOF
}

# Функция отображения информации и запроса данных
setup_validator() {
  clear
  echo "========= 🛠️ Настройка валидатора ========="
  echo "Для управления валидатором необходимо ввести следующие данные:"

  # Запрашиваем данные только в случае, если они еще не сохранены
  if [ -z "$KEYRING_PASSWORD" ]; then
    # Запрашиваем пароль от keyring
    echo
    read -s -p "Введите пароль для keyring: " KEYRING_PASSWORD
    echo
  fi

  if [ -z "$WALLET_NAME" ] || [ -z "$WALLET_ADDRESS" ]; then
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

  # Запрашиваем данные для мониторинга
  if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
    echo
    echo "Если вы хотите включить мониторинг, введите ваш Telegram Bot Token и Chat ID."
    echo "Если мониторинг не требуется, просто нажмите Enter."
    read -p "Введите Telegram Bot Token (или оставьте пустым): " TELEGRAM_BOT_TOKEN
    read -p "Введите Telegram Chat ID (или оставьте пустым): " TELEGRAM_CHAT_ID
  fi

  # Сохраняем все данные в .env файл
  save_env
}

# Функция отображения меню
show_menu() {
  clear
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
      # Здесь вставь команду для снятия комиссий и ревардов
      ;;
    2)
      echo "Сбор ревардов со всех кошельков..."
      # Вставь логику сбора ревардов с multisend или аналогичного скрипта
      ;;
    3)
      echo "Делегирование валидатору со всех кошельков..."
      # Вставь логику делегирования с каждого кошелька
      ;;
    4)
      echo "Запуск интерфейса голосования..."
      # Команда или вызов скрипта голосования
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
      echo "✅ Мониторинг валидатора запущен."
      if [[ -n "$TELEGRAM_BOT_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]]; then
        nohup bash "$HOME/only_monitoring.sh" > /dev/null 2>&1 &
      else
        echo "Мониторинг не был включен, так как не введены данные Telegram."
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
