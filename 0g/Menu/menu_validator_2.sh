#!/bin/bash

# Цвета для вывода
B_GREEN="\e[32m"
B_YELLOW="\e[33m"
B_RED="\e[31m"
NO_COLOR="\e[0m"

# Функция отображения информации и запроса данных
setup_validator() {
  clear
  echo "========= 🛠️ Настройка валидатора ========="
  echo "Для управления валидатором необходимо ввести следующие данные:"
  
  # Запрашиваем пароль от keyring
  echo
  read -s -p "Введите пароль для keyring: " KEYRING_PASSWORD
  echo

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

  # Получаем адрес валидатора
  VALIDATOR_ADDRESS=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_NAME" --bech val -a)

  # Выводим информацию о кошельке и валидаторе
  echo -e "${B_GREEN}Имя кошелька: ${NO_COLOR}$WALLET_NAME"
  echo -e "${B_YELLOW}Адрес кошелька: ${NO_COLOR}$WALLET_ADDRESS"
  echo -e "${B_RED}Адрес валидатора: ${NO_COLOR}$VALIDATOR_ADDRESS"
  
  # Запрашиваем данные для мониторинга
  echo
  echo "Если вы хотите включить мониторинг, введите ваш Telegram Bot Token и Chat ID."
  echo "Если мониторинг не требуется, просто нажмите Enter."
  read -p "Введите Telegram Bot Token (или оставьте пустым): " TELEGRAM_BOT_TOKEN
  read -p "Введите Telegram Chat ID (или оставьте пустым): " TELEGRAM_CHAT_ID
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

# Запуск настройки валидатора
setup_validator

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
