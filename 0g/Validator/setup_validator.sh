#!/bin/bash

# Файл для хранения переменных окружения
ENV_FILE="$HOME/.validator_env"

# Если файл уже существует, просто загружаем его и выходим
if [ -f "$ENV_FILE" ]; then
  echo "$ENV_FILE найден. Загружаем переменные..."
  source "$ENV_FILE"
  echo "Переменные загружены. Повторный ввод не требуется."
  # Не выходим из скрипта и не используем return, просто продолжаем выполнение
else
  # Если переменные еще не загружены, продолжаем работу и запрашиваем их
  # Запрос для загрузки переменных
  echo "Переменные не найдены. Пожалуйста, введите информацию."
fi

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

# Запись переменных в .env файл (с export)
echo "export KEYRING_PASSWORD=\"$KEYRING_PASSWORD\"" > "$ENV_FILE"
echo "export WALLET_NAME=\"$WALLET_NAME\"" >> "$ENV_FILE"
echo "export WALLET_ADDRESS=\"$WALLET_ADDRESS\"" >> "$ENV_FILE"
echo "export VALIDATOR_ADDRESS=\"$VALIDATOR_ADDRESS\"" >> "$ENV_FILE"

# Запись переменных для Telegram только если они были введены
if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
  echo "export TELEGRAM_BOT_TOKEN=\"$TELEGRAM_BOT_TOKEN\"" >> "$ENV_FILE"
  echo "export TELEGRAM_CHAT_ID=\"$TELEGRAM_CHAT_ID\"" >> "$ENV_FILE"
else
  echo "# Telegram settings can be added later when enabling monitoring" >> "$ENV_FILE"
fi


echo ".env файл успешно создан с переменными окружения!"

# Добавляем автозагрузку .validator_env в .bashrc, если она ещё не прописана
BASHRC_FILE="$HOME/.bashrc"

if ! grep -q "source \$HOME/.validator_env" "$BASHRC_FILE"; then
  echo "Добавляем автоматическую загрузку переменных в .bashrc..."
  echo -e "\n# Загрузка переменных окружения для валидатора\nif [ -f \"\$HOME/.validator_env\" ]; then\n  source \"\$HOME/.validator_env\"\nfi" >> "$BASHRC_FILE"
  echo "Готово! Переменные будут автоматически подгружаться при запуске терминала."
else
  echo "Автоматическая загрузка переменных уже настроена."
fi
# === Автоматическая подгрузка переменных при запуске терминала ===

# Определяем текущую оболочку
USER_SHELL=$(basename "$SHELL")
SHELL_RC="$HOME/.bashrc"

if [[ "$USER_SHELL" == "zsh" ]]; then
  SHELL_RC="$HOME/.zshrc"
fi

# Добавляем source .validator_env в RC-файл (если не добавлен)
if ! grep -q 'source \$HOME/.validator_env' "$SHELL_RC" && ! grep -q 'source $HOME/.validator_env' "$SHELL_RC"; then
  echo "Добавляем автоматическую подгрузку переменных в $SHELL_RC..."
  echo -e "\n# Загрузка переменных валидатора\nif [ -f \"\$HOME/.validator_env\" ]; then\n  source \"\$HOME/.validator_env\"\nfi" >> "$SHELL_RC"
  echo "✅ Добавлено в $SHELL_RC"
else
  echo "✅ Автозагрузка уже настроена в $SHELL_RC"
fi

# Обеспечиваем запуск RC-файла при login-сессии
PROFILE_FILE="$HOME/.profile"
if [ "$SHELL_RC" = "$HOME/.bashrc" ]; then
  if ! grep -q 'source ~/.bashrc' "$PROFILE_FILE"; then
    echo "Добавляем source ~/.bashrc в ~/.profile для login-сессий..."
    echo 'source ~/.bashrc' >> "$PROFILE_FILE"
    echo "✅ Добавлено в ~/.profile"
  else
    echo "✅ ~/.profile уже запускает ~/.bashrc"
  fi
fi

echo "✅ Настройка завершена."
echo "source $SHELL_RC"

# Загружаем переменные сразу после создания .env
if [ -f "$HOME/.validator_env" ]; then
  source "$HOME/.validator_env"
fi
echo "✅ Введенные переменные загружены."

# Добавляем команду для загрузки меню после всех установок переменных
echo "Загружаем меню..."
source <(wget -qO- 'https://raw.githubusercontent.com/80an/Nodes/refs/heads/0G_create_menu/0g/Validator/menu_validator.sh')

