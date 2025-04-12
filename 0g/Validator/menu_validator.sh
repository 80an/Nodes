#!/bin/bash

# Файл для хранения переменных окружения
ENV_FILE="$HOME/.validator_env"
BASHRC_FILE="$HOME/.bashrc"

# Проверка, существует ли файл .env и загрузка переменных, если он существует
if [ -f "$ENV_FILE" ]; then
  echo
  echo "$ENV_FILE найден. Загружаем переменные..."
  # Загружаем переменные из .validator_env файла
  echo
  source "$ENV_FILE"
  echo "Переменные успешно загружены из .validator_env файла."
else
  
  echo
  
  echo "$ENV_FILE не найден. Выполним настройку переменных."
  
 echo
read -s -p "Введите пароль для Keyring: " KEYRING_PASSWORD
echo

echo "Выберите, что вводить:"
echo "1) Имя кошелька"
echo "2) Адрес кошелька"
read -p "Что выбираете? (1 или 2): " choice

if [ "$choice" -eq 1 ]; then
  read -p "Введите имя кошелька: " WALLET_NAME

  # Получаем адрес кошелька
  WALLET_ADDRESS=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_NAME" --bech acc -a 2>/dev/null)
  if [ -z "$WALLET_ADDRESS" ]; then
    echo "❌ Ошибка: Кошелек '$WALLET_NAME' не найден."
    exit 1
  fi
elif [ "$choice" -eq 2 ]; then
  read -p "Введите адрес кошелька (начинается на 0g...): " WALLET_ADDRESS

  # Получаем имя кошелька по адресу
  WALLET_NAME=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_ADDRESS" --output json | jq -r '.name' 2>/dev/null)
  if [ -z "$WALLET_NAME" ]; then
    echo "❌ Ошибка: Не удалось найти имя кошелька для адреса '$WALLET_ADDRESS'."
    exit 1
  fi
else
  echo "Неверный выбор. Пожалуйста, выберите 1 или 2."
  exit 1
fi

# Получаем адрес валидатора
  VALIDATOR_ADDRESS=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_NAME" --bech val -a 2>/dev/null)
  if [ -z "$VALIDATOR_ADDRESS" ]; then
    echo "❌ Ошибка: Не удалось найти адрес валидатора для кошелька '$WALLET_NAME'."
    exit 1
  fi

# Запрос токена и чат ID с возможностью пропустить ввод
  echo
  read -p "Введите токен (или нажмите ENTER, чтобы пропустить): " TOKEN
  echo
  read -p "Введите чат ID (или нажмите ENTER, чтобы пропустить): " CHAT_ID

# Сохраняем переменные в файл
{
  echo "KEYRING_PASSWORD=\"$KEYRING_PASSWORD\""
  echo "WALLET_NAME=\"$WALLET_NAME\""
  echo "WALLET_ADDRESS=\"$WALLET_ADDRESS\""
  echo "VALIDATOR_ADDRESS=\"$VALIDATOR_ADDRESS\""
  [ -n "$TOKEN" ] && echo "TOKEN=\"$TOKEN\""
  [ -n "$CHAT_ID" ] && echo "CHAT_ID=\"$CHAT_ID\""
} > "$HOME/.validator_env"

  echo
  echo ".validator_env файл успешно создан с переменными:"
  echo "  WALLET_NAME: $WALLET_NAME"
  echo "  WALLET_ADDRESS: $WALLET_ADDRESS"
  echo "  VALIDATOR_ADDRESS: $VALIDATOR_ADDRESS"
  [ -n "$TOKEN" ] && echo "  TOKEN: $TOKEN"
  [ -n "$CHAT_ID" ] && echo "  CHAT_ID: $CHAT_ID"
fi

# Проверка, существует ли уже команда для автоматической загрузки переменных в .bashrc
if ! grep -q "source \$HOME/.validator_env" "$BASHRC_FILE"; then
  echo "Добавляем автоматическую загрузку переменных из .validator_env в .bashrc..."
  echo -e "\n# Загрузка переменных окружения из .validator_env\nif [ -f \"\$HOME/.validator_env\" ]; then\n  source \"\$HOME/.validator_env\"\nfi" >> "$BASHRC_FILE"
  echo "Команда для загрузки переменных добавлена в .bashrc."
else
  echo "Автоматическая загрузка переменных уже настроена в .bashrc."
fi

# Меню для управления валидатором
while true; do
  echo
  echo "========= 📋 Меню управления валидатором ========="
  echo "1) 💰 Забрать комиссии и реварды валидатора"
  echo "2) 💸 Забрать все реварды со всех кошельков"
  echo "3) 📥 Делегировать со всех кошельков в своего валидатора"
  echo "4) 🗳 Голосование по пропозалу"
  echo "5) 🚪 Вызволить из тюрьмы"
  echo "6) ✅ Мониторинг валидатора"
  echo "7) 📜 Мониторинг пропозалов"
  echo "8) ❌ Выход"
  echo "=================================================="
  echo

  read -p "Выберите пункт меню (1-8): " choice

    case $choice in
    1)
      echo "💰 Забрать комиссии и реварды валидатора"
      # Пример: команда для снятия наград и комиссий
      # $BINARY tx distribution withdraw-rewards $VALIDATOR_ADDRESS --commission --from $WALLET_NAME --chain-id $CHAIN_ID --gas auto --fees 5000$DENOM -y
      ;;
    2)
      echo "💸 Забрать все реварды со всех кошельков"
      # Здесь нужно перечислить все адреса и выполнить команду withdraw-rewards для каждого
      ;;
    3)
      echo "📥 Делегировать со всех кошельков в своего валидатора"
      # Аналогично, цикл по адресам, делегирование оставшихся средств
      ;;
    4)
      echo "🗳 Голосование по пропозалу"
      read -p "Введите номер пропозала: " proposal
      read -p "Введите ваш голос (yes/no/abstain/no_with_veto): " vote
      # $BINARY tx gov vote $proposal $vote --from $WALLET_NAME --chain-id $CHAIN_ID --fees 5000$DENOM -y
      ;;
    5)
      echo "🚪 Вызволить из тюрьмы"
      # $BINARY tx slashing unjail --from $WALLET_NAME --chain-id $CHAIN_ID --fees 5000$DENOM -y
      ;;
    6)
      while true; do
        echo
        echo "=== ✅ Подменю мониторинга валидатора ==="
        echo "1) ▶️ Включить мониторинг"
        echo "2) 📊 Состояние мониторинга"
        echo "3) ⏹ Отключить мониторинг"
        echo "4) 🔙 Вернуться в главное меню"
        echo "========================================="
        read -p "Выберите действие (1-4): " subchoice

        case $subchoice in
          1)
            echo "▶️ Включаем мониторинг валидатора..."
            # Пример: запуск мониторинга как systemd-сервис или screen/tmux
            ;;
          2)
            echo "📊 Проверяем статус мониторинга валидатора..."
            # Пример: проверка состояния процесса или сервиса
            ;;
          3)
            echo "⛔ Останавливаем мониторинг валидатора..."
            # Пример: остановка мониторинга
            ;;
          4)
            echo "🔙 Возвращаемся в главное меню..."
            break
            ;;
          *)
            echo "🚫 Неверный выбор, пожалуйста, выберите от 1 до 4."
            ;;
        esac
      done
      ;;
    7)
      while true; do
        echo
        echo "=== 📜 Подменю мониторинга пропозалов ==="
        echo "1) ▶️ Включить мониторинг"
        echo "2) 📊 Состояние мониторинга"
        echo "3) ⏹ Отключить мониторинг"
        echo "4) 🔙 Вернуться в главное меню"
        echo "========================================="
        read -p "Выберите действие (1-4): " subchoice

        case $subchoice in
          1)
            echo "▶️ Включаем мониторинг пропозалов..."
            # Запуск мониторинга
            ;;
          2)
            echo "📊 Проверяем статус мониторинга пропозалов..."
            # Проверка процесса или логов
            ;;
          3)
            echo "⛔ Останавливаем мониторинг пропозалов..."
            # Остановка мониторинга
            ;;
          4)
            echo "🔙 Возвращаемся в главное меню..."
            break
            ;;
          *)
            echo "🚫 Неверный выбор, пожалуйста, выберите от 1 до 4."
            ;;
        esac
      done
      ;;
    8)
      echo "❌ Выход из программы..."
      break
      ;;
    *)
      echo "🚫 Неверный выбор, пожалуйста, выберите пункт от 1 до 8."
      ;;
  esac
done

