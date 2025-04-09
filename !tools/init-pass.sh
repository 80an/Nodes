#!/bin/bash

set -e

echo -e "\n🔐 Установка pass и GPG..."
sudo apt update -y
sudo apt install -y pass gnupg2

# Проверка наличия GPG ключей
if ! gpg --list-keys | grep -q "^pub"; then
  echo -e "\n🛠️ GPG-ключ не найден, создаём автоматически..."
  export GNUPGHOME=$(mktemp -d)
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
  unset GNUPGHOME
else
  echo -e "\n✅ Найден GPG-ключ:"
  gpg --list-keys
  GPG_ID=$(gpg --list-keys --with-colons | grep '^pub' | cut -d':' -f5 | head -n1)
fi

echo -e "\n🚀 Инициализация pass с ключом: $GPG_ID"
pass init "$GPG_ID"

echo -e "\n🔑 Введите KEYRING_PASSWORD для валидатора:"
read -s KEYRING_PASSWORD

echo "$KEYRING_PASSWORD" | pass insert -m validator/keyring_password

echo -e "\n✅ Пароль сохранён! Теперь можно использовать его так:"
echo -e '\nKEYRING_PASSWORD=$(pass validator/keyring_password)'

# Пример автоподстановки
if [[ $1 == "--test" ]]; then
  echo -e "\n🔁 Тестовая подстановка:"
  KEYRING_PASSWORD=$(pass validator/keyring_password)
  echo "KEYRING_PASSWORD=${KEYRING_PASSWORD:0:4}****"
fi

