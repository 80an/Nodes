# Проверка, что переменная KEYRING_PASSWORD загружена
if [ -z "$KEYRING_PASSWORD" ]; then
  echo "❌ Переменная KEYRING_PASSWORD не установлена. Пожалуйста, сначала запустите start.sh."
  exit 1
fi

# Выбираем, что вводить - имя кошелька или адрес
echo "Выберите, что вводить:"
echo "1) Имя кошелька"
echo "2) Адрес кошелька"
read -p "Что выбираете? (1 или 2): " choice

if [ "$choice" -eq 1 ]; then
  read -p "Введите имя кошелька: " WALLET_NAME
  WALLET_ADDRESS=$(echo "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_NAME" --bech acc -a)
elif [ "$choice" -eq 2 ]; then
  read -p "Введите адрес кошелька: " WALLET_ADDRESS
  WALLET_NAME=$(echo "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_ADDRESS" --output json | jq -r '.name')
else
  echo "❌ Неверный выбор. Пожалуйста, выберите 1 или 2."
  exit 1
fi

VALIDATOR_ADDRESS=$(echo "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_NAME" --bech val -a)

# Запрос на ввод Telegram данных (опционально)
echo "Если хотите, можете пропустить ввод данных для Telegram. Эти данные можно будет ввести позже."
read -p "Введите токен Telegram-бота (или нажмите Enter, чтобы пропустить): " TELEGRAM_BOT_TOKEN
read -p "Введите Chat ID Telegram (или нажмите Enter, чтобы пропустить): " TELEGRAM_CHAT_ID

# Добавляем переменные в файл окружения
ENV_FILE="$HOME/.validator_env"
{
  echo "export WALLET_NAME=\"$WALLET_NAME\""
  echo "export WALLET_ADDRESS=\"$WALLET_ADDRESS\""
  echo "export VALIDATOR_ADDRESS=\"$VALIDATOR_ADDRESS\""
  if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
    echo "export TELEGRAM_BOT_TOKEN=\"$TELEGRAM_BOT_TOKEN\""
    echo "export TELEGRAM_CHAT_ID=\"$TELEGRAM_CHAT_ID\""
  else
    echo "# Telegram settings can be added later"
  fi
} >> "$ENV_FILE"

# Загружаем переменные в текущую сессию
source "$ENV_FILE"

echo "✅ Переменные успешно сохранены и загружены."
echo "🔄 Переход к меню..."
source <(wget -qO- 'https://raw.githubusercontent.com/80an/Nodes/refs/heads/Punkty-menu/0g/Validator/menu_validator.sh')
