#!/bin/bash

# Файл для хранения переменных окружения
ENV_FILE="$HOME/.validator_env"

# Запрашиваем пароль для Keyring
read -s -p "Введите пароль для Keyring: " KEYRING_PASSWORD
echo

# Выбираем, что вводить - имя кошелька или адрес
echo "Выберите, что вводить:"
echo "1) Имя кошелька"
echo "2) Адрес кошелька"
read -p "Что выбираете? (1 или 2): " choice

if [ "$choice" -eq 1 ]; then
  # Вводим имя кошелька
  read -p "Введите имя кошелька: " WALLET_NAME
  # Получаем адрес кошелька на основе имени
  WALLET_ADDRESS=$(echo "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_NAME" --bech acc -a)
elif [ "$choice" -eq 2 ]; then
  # Вводим адрес кошелька
  read -p "Введите адрес кошелька: " WALLET_ADDRESS
  # Получаем имя кошелька на основе адреса
  WALLET_NAME=$(echo "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_ADDRESS" --output json | jq -r '.name')
else
  echo "Неверный выбор. Пожалуйста, выберите 1 или 2."
  exit 1
fi

# Получаем адрес валидатора на основе имени кошелька
VALIDATOR_ADDRESS=$(echo "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_NAME" --bech val -a)

# Запрос на ввод Telegram данных (с возможностью пропуска)
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
