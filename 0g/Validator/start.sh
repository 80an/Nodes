#!/bin/bash

# Файл для хранения переменных окружения
ENV_FILE="$HOME/.validator_env"

# Проверка, существует ли уже переменная окружения для пароля
if [ -z "$KEYRING_PASSWORD" ]; then
  echo "Пароль для Keyring не найден. Запрашиваем пароль..."

  # Запрашиваем пароль для Keyring
  read -s -p "Введите пароль для Keyring: " KEYRING_PASSWORD
  echo

  # Записываем пароль в файл переменных окружения для дальнейшего использования
  echo "export KEYRING_PASSWORD=\"$KEYRING_PASSWORD\"" > "$ENV_FILE"
  echo ".env файл с паролем успешно создан!"
else
  echo "Пароль для Keyring уже установлен."
fi

# Загружаем переменные окружения, если они были сохранены
if [ -f "$ENV_FILE" ]; then
  source "$ENV_FILE"
  echo "Переменные загружены."
fi

# Теперь запускаем следующий скрипт для настройки валидатора
source <(wget -qO- 'https://raw.githubusercontent.com/80an/Nodes/refs/heads/Punkty-menu/0g/Validator/setup_validator.sh')
