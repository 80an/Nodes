#!/bin/bash

# Скрипт для настройки переменных и запуска основного меню

echo "🔧 Запуск настройки валидатора..."

# Запрос пароля keyring
echo
read -sp "Введите пароль keyring: " KEYRING_PASSWORD
echo

# Выбор способа ввода
echo "Выберите, что вводить:"
echo "1) Имя кошелька"
echo "2) Адрес кошелька"
read -p "Что выбираете? (1 или 2): " choice

if [ "$choice" -eq 1 ]; then
  read -p "Введите имя кошелька: " WALLET_NAME
  WALLET_ADDRESS=$(echo "$KEYRING_PASSWORD" | xargs -0 printf "%s" | 0gchaind keys show "$WALLET_NAME" --bech acc -a)
elif [ "$choice" -eq 2 ]; then
  read -p "Введите адрес кошелька: " WALLET_ADDRESS
  WALLET_NAME=$(echo "$KEYRING_PASSWORD" | xargs -0 printf "%s" | 0gchaind keys show "$WALLET_ADDRESS" --output json | jq -r '.name')
else
  echo "❌ Неверный выбор. Пожалуйста, выберите 1 или 2."
  exit 1
fi

# Вычисляем адрес валидатора
VALIDATOR_ADDRESS=$(echo "$KEYRING_PASSWORD" | xargs -0 printf "%s" | 0gchaind keys show "$WALLET_NAME" --bech val -a)

# Сохраняем переменные в файл (экранируем спецсимволы)
echo "💾 Сохраняем переменные..."
mkdir -p ~/.validator_config
cat > ~/.validator_config/env <<EOF
KEYRING_PASSWORD='$(printf "%q" "$KEYRING_PASSWORD")'
WALLET_NAME='$WALLET_NAME'
WALLET_ADDRESS='$WALLET_ADDRESS'
VALIDATOR_ADDRESS='$VALIDATOR_ADDRESS'
EOF

# Создаём команду для запуска основного меню
echo ""
echo "🚀 Создаём команду 'validator' для быстрого запуска меню..."

mkdir -p "$HOME/bin"
cat > "$HOME/bin/validator" <<EOF
#!/bin/bash
source "\$HOME/0g/Validator/menu_validator.sh"
EOF
chmod +x "$HOME/bin/validator"

# Добавляем ~/bin в PATH, если ещё не добавлен
PROFILE_FILE="$HOME/.bashrc"
if ! grep -q 'export PATH="\$HOME/bin:\$PATH"' "$PROFILE_FILE"; then
  echo "export PATH=$HOME/bin:\$PATH" >> "$PROFILE_FILE"
  # echo 'export PATH="$HOME/bin:$PATH"' >> "$PROFILE_FILE"
  export PATH="$HOME/bin:$PATH"
  echo "✅ Путь ~/bin добавлен в .bashrc и активирован."
else
  export PATH="$HOME/bin:$PATH"
fi

echo ""
echo "✅ Настройка завершена."
echo "Теперь вы можете запускать меню в любой момент командой:"
echo "    validator"
