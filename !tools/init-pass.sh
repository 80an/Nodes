#!/bin/bash

set -e

echo -e "\n🔐 Установка pass и GPG..."
sudo apt update -y
sudo apt install -y pass gnupg2

# Проверка наличия GPG ключей
if ! gpg --list-keys | grep -q "^pub"; then
  echo -e "\n🛠️ GPG-ключ не найден, создаём автоматически..."

  # Генерация нового GPG ключа
  cat >gen-key-script <<EOF
%echo Generating GPG key
Key-Type: RSA
Key-Length: 4096
Name-Real: Validator
Name-Email: validator@example.com
Expire-Date: 0
%no-protection
%commit
%echo Done
EOF

  gpg --batch --gen-key gen-key-script
  rm gen-key-script

  GPG_ID=$(gpg --list-keys --with-colons | grep '^pub' | cut -d':' -f5 | head -n1)
else
  echo -e "\n✅ Найден GPG-ключ:"
  gpg --list-keys
  GPG_ID=$(gpg --list-keys --with-colons | grep '^pub' | cut -d':' -f5 | head -n1)
fi

echo -e "\n🚀 Инициализация pass с ключом: $GPG_ID"
pass init "$GPG_ID"

# Сохраняем пароль в pass
echo -e "\n🔑 Введите KEYRING_PASSWORD для валидатора:"
read -s KEYRING_PASSWORD
echo "$KEYRING_PASSWORD" | pass insert -m validator/keyring_password

echo -e "\n✅ Пароль сохранён! Теперь можно использовать его так:"
echo -e '\nKEYRING_PASSWORD=$(pass validator/keyring_password)'

# Функция для безопасного получения пароля
get_keyring_password() {
  # Загружаем пароль из pass только при необходимости
  local password
  password=$(pass validator/keyring_password)
  echo "$password"
}

# Пример выполнения команды с использованием pass для скриптов
run_command_with_pass() {
  # Временно загружаем переменную окружения для команды
  export KEYRING_PASSWORD=$(get_keyring_password)
  
  # Выполнение команды с использованием пароля
  echo "Выполнение команды: $1"
  eval "$1"
  
  # Сбрасываем переменную окружения после выполнения команды
  unset KEYRING_PASSWORD
}

# Пример команды для получения списка кошельков (не использовать pass, запросим пароль вручную)
if [[ $1 == "--list-keys" ]]; then
  echo -e "\n🔑 Запрос пароля для выполнения команды 0gchaind keys list..."
  # Команда, которая будет запрашивать пароль вручную через keyring
  0gchaind keys list --keyring-backend file
fi

# Пример команды для получения адреса кошелька (не использовать pass, запросим пароль вручную)
if [[ $1 == "--get-wallet" ]]; then
  echo -e "\n🔑 Запрос пароля для получения адреса кошелька..."
  # Команда, которая будет запрашивать пароль вручную через keyring
  0gchaind keys show wallet --bech acc -a --keyring-backend file
fi

# Пример использования pass в скрипте для выполнения команд
if [[ $1 == "--some-script" ]]; then
  echo -e "\nЗапуск автоматической команды через pass..."
  run_command_with_pass "0gchaind query staking validator <validator-address> --keyring-backend file"
fi
