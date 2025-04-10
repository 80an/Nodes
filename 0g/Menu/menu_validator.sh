#!/bin/bash

# Файл для хранения переменных окружения
ENV_FILE="$HOME/.env"
BASHRC_FILE="$HOME/.bashrc"

# Проверка, существует ли файл .env и загрузка переменных, если он существует
if [ -f "$ENV_FILE" ]; then
  echo "$ENV_FILE найден. Загружаем переменные..."
  # Загружаем переменные из .env файла
  source "$ENV_FILE"
  echo "Переменные успешно загружены из .env файла."
else
  echo "$ENV_FILE не найден. Выполним настройку переменных."
  
  # Ввод данных пользователя для настройки
  read -s -p "Введите пароль для Keyring: " KEYRING_PASSWORD
  echo
  echo "Выберите, что вводить:"
  echo "1) Имя кошелька"
  echo "2) Адрес кошелька"
  read -p "Что выбираете? (1 или 2): " choice

  if [ "$choice" -eq 1 ]; then
    # Вводим имя кошелька
    read -p "Введите имя кошелька: " WALLET_NAME
    # Получаем адрес кошелька и валидатора на основе имени кошелька
    WALLET_ADDRESS=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_NAME" --bech acc -a)
    VALIDATOR_ADDRESS=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_NAME" --bech val -a)
  elif [ "$choice" -eq 2 ]; then
    # Вводим адрес кошелька
    read -p "Введите адрес кошелька: " WALLET_ADDRESS
    # Получаем имя кошелька и валидатора на основе адреса кошелька
    WALLET_NAME=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_ADDRESS" --output json | jq -r '.name')
    VALIDATOR_ADDRESS=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_NAME" --bech val -a)
  else
    echo "Неверный выбор. Пожалуйста, выберите 1 или 2."
    exit 1
  fi

  # Запрос на ввод Telegram переменных (с возможностью пропуска)
  echo "Если хотите, можете пропустить ввод данных для Telegram. Эти данные можно будет ввести при попытке включить мониторинг."
  read -p "Введите токен Telegram-бота (или нажмите Enter, чтобы пропустить): " TELEGRAM_BOT_TOKEN
  read -p "Введите Chat ID Telegram (или нажмите Enter, чтобы пропустить): " TELEGRAM_CHAT_ID

  # Запись переменных в .env файл
  echo "KEYRING_PASSWORD=\"$KEYRING_PASSWORD\"" > "$ENV_FILE"
  echo "WALLET_NAME=\"$WALLET_NAME\"" >> "$ENV_FILE"
  echo "WALLET_ADDRESS=\"$WALLET_ADDRESS\"" >> "$ENV_FILE"
  echo "VALIDATOR_ADDRESS=\"$VALIDATOR_ADDRESS\"" >> "$ENV_FILE"

  # Запись переменных для Telegram только если они были введены
  if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
    echo "TELEGRAM_BOT_TOKEN=\"$TELEGRAM_BOT_TOKEN\"" >> "$ENV_FILE"
    echo "TELEGRAM_CHAT_ID=\"$TELEGRAM_CHAT_ID\"" >> "$ENV_FILE"
  else
    echo "# Telegram settings can be added later when enabling monitoring" >> "$ENV_FILE"
  fi

  echo ".env файл успешно создан с переменными окружения!"
fi

# Проверка, существует ли уже команда для автоматической загрузки переменных в .bashrc
if ! grep -q "source \$HOME/.env" "$BASHRC_FILE"; then
  echo "Добавляем автоматическую загрузку переменных из .env в .bashrc..."
  # Добавляем команду в .bashrc, чтобы переменные автоматически загружались при каждом входе в систему
  echo -e "\n# Загрузка переменных окружения из .env\nif [ -f \"\$HOME/.env\" ]; then\n  source \"\$HOME/.env\"\nfi" >> "$BASHRC_FILE"
  echo "Команда для загрузки переменных добавлена в .bashrc."
else
  echo "Автоматическая загрузка переменных уже настроена в .bashrc."
fi

# Меню для управления валидатором
while true; do
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
  
  read -p "Выберите пункт меню (1-8): " choice

  case $choice in
    1)
      echo "Собираем комиссии и реварды валидатора..."
      # Здесь добавьте код для сбора комиссий и ревардов
      ;;
    2)
      echo "Собираем реварды со всех кошельков..."
      # Здесь добавьте код для сбора ревардов со всех кошельков
      ;;
    3)
      echo "Делегируем валидатору со всех кошельков..."
      # Здесь добавьте код для делегирования
      ;;
    4)
      echo "Переходим к голосованию..."
      # Здесь добавьте код для голосования
      ;;
    5)
      echo "Выход из тюрьмы (unjail)..."
      # Здесь добавьте код для выхода из тюрьмы (unjail)
      ;;
    6)
      # Включаем мониторинг валидатора
      if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
        echo "Telegram настройки не были введены. Пожалуйста, введите их."
        read -p "Введите токен Telegram-бота: " TELEGRAM_BOT_TOKEN
        read -p "Введите Chat ID Telegram: " TELEGRAM_CHAT_ID

        # Сохраняем новые данные в .env
        echo "TELEGRAM_BOT_TOKEN=\"$TELEGRAM_BOT_TOKEN\"" >> "$ENV_FILE"
        echo "TELEGRAM_CHAT_ID=\"$TELEGRAM_CHAT_ID\"" >> "$ENV_FILE"
      fi
      echo "Включаем мониторинг валидатора..."
      # Здесь добавьте код для включения мониторинга
      ;;
    7)
      echo "Отключаем мониторинг валидатора..."
      # Здесь добавьте код для отключения мониторинга
      ;;
    8)
      echo "Выход из программы..."
      break  # Это заменяет exit 0 и не завершает сессию
      ;;
    *)
      echo "Неверный выбор, пожалуйста, выберите пункт от 1 до 8."
      ;;
  esac
done

