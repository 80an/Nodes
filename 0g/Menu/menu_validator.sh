#!/bin/bash

# Файл для хранения переменных окружения
ENV_FILE="$HOME/.env"
BASHRC_FILE="$HOME/.bashrc"


# Проверка, существует ли файл .env и загрузка переменных, если он существует
if [ -f "$ENV_FILE" ]; then
  echo "$ENV_FILE найден. Загружаем переменные..."
  # Загружаем переменные из .env файла
  source "$ENV_FILE"
  echo "Переменные успешно загружены из .env файла."

else
  echo "$ENV_FILE не найден. Выполним настройку переменных."
  
  # Ввод данных пользователя для настройки
  read -s -p "Введите пароль для Keyring: " KEYRING_PASSWORD
  echo

  echo "Выберите, что вводить:"
  echo "1) Имя кошелька"
  echo "2) Адрес кошелька"
  read -p "Что выбираете? (1 или 2): " choice

  if [ "$choice" -eq 1 ]; then
    # Вводим имя кошелька
    read -p "Введите имя кошелька: " WALLET_NAME

    # Получаем адрес кошелька и валидатора на основе имени кошелька
    WALLET_ADDRESS=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_NAME" --bech acc -a)
    VALIDATOR_ADDRESS=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_NAME" --bech val -a)

  elif [ "$choice" -eq 2 ]; then
    # Вводим адрес кошелька
    read -p "Введите адрес кошелька: " WALLET_ADDRESS

    # Получаем имя кошелька и валидатора на основе адреса кошелька
    WALLET_NAME=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_ADDRESS" --output json | jq -r '.name')
    VALIDATOR_ADDRESS=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_NAME" --bech val -a)

  else
    echo "Неверный выбор. Пожалуйста, выберите 1 или 2."
    exit 1
  fi

  # Запрос на ввод Telegram переменных (с возможностью пропуска)
  echo
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

  echo
  echo ".env файл успешно создан с переменными окружения!"
fi


# Проверка, существует ли уже команда для автоматической загрузки переменных в .bashrc
if ! grep -q "source \$HOME/.env" "$BASHRC_FILE"; then
  echo "Добавляем автоматическую загрузку переменных из .env в .bashrc..."
  echo -e "\n# Загрузка переменных окружения из .env\nif [ -f \"\$HOME/.env\" ]; then\n  source \"\$HOME/.env\"\nfi" >> "$BASHRC_FILE"
  echo "Команда для загрузки переменных добавлена в .bashrc."
else
  echo "Автоматическая загрузка переменных уже настроена в .bashrc."
fi


# Меню для управления валидатором
while true; do
  echo
  echo "========= 📋 Меню управления валидатором ========="
  echo "1) 💰 Собрать комиссии и реварды валидатора"
  echo "2) 💸 Собрать реварды со всех кошельков"
  echo "3) 📥 Делегировать валидатору со всех кошельков"
  echo "4) 🗳 Голосование"
  echo "5) 🚪 Выход из тюрьмы (unjail)"
  echo "6) ✅ Управление мониторингом валидатора"
  echo "7) ⛔ Пока пустое"
  echo "8) ❌ Выход"
  echo "=================================================="
  echo

  read -p "Выберите пункт меню (1-8): " choice

  case $choice in
    1)
       echo "Собрать комиссии и реварды валидатора..."
      printf "%s" "$KEYRING_PASSWORD" | 0gchaind tx distribution withdraw-rewards \
        --from "$WALLET_NAME" \
        --commission \
        --chain-id zgtendermint_16600-2 \
        --gas-adjustment 1.7 \
        --gas auto \
        --gas-prices 0.003ua0gi \
        -y
      echo
      ;;
    2)
      echo 
      echo "💰 Собираем реварды со всех кошельков..."
      source <(wget -qO- 'https://raw.githubusercontent.com/80an/Nodes/refs/heads/main/0g/all_reward.sh')
      echo
      ;;
    3)
      echo
      echo "📥 Делегируем валидатору со всех кошельков..."
      source <(wget -qO- 'https://raw.githubusercontent.com/80an/Nodes/refs/heads/main/0g/all_delegation.sh')
      echo
      ;;
    4)
      echo
      echo "🗳 Голосование (мониторинг пропозалов будет запущен в фоне)..."
      source <(wget -qO- 'https://raw.githubusercontent.com/80an/Nodes/refs/heads/main/0g/monitoring_proposal.sh')
      echo
      ;;
    5)
      echo
      echo "🚪 Выход из тюрьмы (unjail)..."
      printf "%s" "$KEYRING_PASSWORD" | 0gchaind tx slashing unjail \
        --from "$WALLET_NAME" \
        --chain-id zgtendermint_16600-2 \
        --gas-adjustment 1.7 \
        --gas auto \
        --gas-prices 0.003ua0gi \
        -y
      echo
      ;;
    6)
      
     # Проверяем наличие необходимых переменных          
           if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
              echo "Telegram настройки не были введены. Пожалуйста, введите их."
              read -p "Введите токен Telegram-бота: " TELEGRAM_BOT_TOKEN
              read -p "Введите Chat ID Telegram: " TELEGRAM_CHAT_ID

              # Сохраняем новые данные в .env
              echo "TELEGRAM_BOT_TOKEN=\"$TELEGRAM_BOT_TOKEN\"" >> "$ENV_FILE"
              echo "TELEGRAM_CHAT_ID=\"$TELEGRAM_CHAT_ID\"" >> "$ENV_FILE"
            fi
      # Сохраняем новые данные в .env (добавляем, если они не были сохранены) Это доп проверка если будут ошибки
       # if ! grep -q "TELEGRAM_BOT_TOKEN" "$ENV_FILE"; then
       #     echo "TELEGRAM_BOT_TOKEN=\"$TELEGRAM_BOT_TOKEN\"" >> "$ENV_FILE"
       # fi
       # if ! grep -q "TELEGRAM_CHAT_ID" "$ENV_FILE"; then
       #     echo "TELEGRAM_CHAT_ID=\"$TELEGRAM_CHAT_ID\"" >> "$ENV_FILE"
       # fi
   # fi
      
      # Включаем подменю для мониторинга валидатора
      while true; do
        echo "Управление мониторингом валидатора:"
        echo "1) Запустить мониторинг"
        echo "2) Остановить мониторинг"
        echo "3) Проверить статус мониторинга"
        echo "4) Вернуться в главное меню"
        read -p "Выберите действие: " sub_choice

        case $sub_choice in
          1)
            # Включаем мониторинг валидатора
            MONITOR_PID_FILE="$HOME/.monitor_pid"
            
            if [ -f "$MONITOR_PID_FILE" ]; then
              echo "❌ Мониторинг уже запущен!"
            else
              # Запуск мониторинга
              echo "🚀 Запуск мониторинга валидатора..."
              nohup bash -c "source <(wget -qO- 'https://raw.githubusercontent.com/80an/Nodes/refs/heads/main/0g/monitoring_validator.sh')" > /dev/null 2>&1 &
              echo $! > "$MONITOR_PID_FILE"
              echo "✅ Мониторинг запущен с PID: $(cat $MONITOR_PID_FILE)"
            fi
            ;;
          2)
            # Остановить мониторинг валидатора
            if [ -f "$MONITOR_PID_FILE" ]; then
              PID=$(cat "$MONITOR_PID_FILE")
              kill "$PID"
              rm "$MONITOR_PID_FILE"
              echo "✅ Мониторинг остановлен (PID: $PID)"
            else
              echo "❌ Мониторинг не был запущен."
            fi
            ;;
          3)
            # Проверить статус мониторинга
            if [ -f "$MONITOR_PID_FILE" ]; then
              PID=$(cat "$MONITOR_PID_FILE")
              echo "🟢 Мониторинг запущен с PID: $PID"
            else
              echo "❌ Мониторинг не запущен."
            fi
            ;;
          4)
            echo "Назад в основное меню..."
            break
            ;;
          *)
            echo "🚫 Неверный выбор, пожалуйста, выберите пункт от 1 до 4."
            ;;
        esac
      done
      ;;
    7)
      echo
      echo "⛔ Пока пустое меню..."
      echo
      ;;
    8)
      echo "❌ Выход из программы..."
      break  # Это заменяет exit 0 и не завершает сессию
      ;;
    *)
      echo "🚫 Неверный выбор, пожалуйста, выберите пункт от 1 до 8."
      ;;
  esac
done

