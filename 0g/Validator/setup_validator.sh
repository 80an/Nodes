#!/bin/bash

# Файл для хранения переменных окружения
ENV_FILE="$HOME/.validator_env"

# Если файл уже существует, просто загружаем его и выходим
if [ -f "$ENV_FILE" ]; then
  echo "$ENV_FILE найден. Загружаем переменные..."
  source "$ENV_FILE"
  echo "Переменные загружены. Повторный ввод не требуется."
  return 0 2>/dev/null || exit 0
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

# Меню для управления валидатором========================================================================================================================
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
