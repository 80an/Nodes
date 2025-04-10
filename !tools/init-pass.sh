#!/bin/bash

# Проверка инициализации pass и наличия сохранённого пароля
if ! command -v pass &> /dev/null || ! pass show validator/keyring_password &> /dev/null; then
  echo -e "\n🔐 Настройка менеджера паролей pass..."
  source <(wget -qO- 'https://raw.githubusercontent.com/80an/Nodes/refs/heads/main/!tools/init-pass.sh')
fi

# Меню для управления валидатором
PS3='Выберите действие: '
options=("Запросить список кошельков" "Запросить адрес кошелька" "Выход")
select opt in "${options[@]}"
do
  case $opt in
    "Запросить список кошельков")
      echo -e "\n🔑 Запрос пароля для выполнения команды 0gchaind keys list..."
      # Команда, которая будет запрашивать пароль вручную через keyring
      0gchaind keys list --keyring-backend file
      ;;
    "Запросить адрес кошелька")
      echo -e "\n🔑 Запрос пароля для получения адреса кошелька..."
      # Команда, которая будет запрашивать пароль вручную через keyring
      0gchaind keys show wallet --bech acc -a --keyring-backend file
      ;;
    "Выход")
      echo "Выход из меню"
      break
      ;;
    *)
      echo "Неверный выбор. Пожалуйста, выберите правильный вариант."
      ;;
  esac
done

