#!/bin/bash

# Цвета для вывода
B_GREEN="\e[32m"
B_YELLOW="\e[33m"
B_BLUE="\e[34m"
B_RED="\e[31m"
B_CYAN="\e[36m"
B_MAGENTA="\e[35m"
NO_COLOR="\e[0m"

# Файл для хранения переменных окружения
ENV_FILE="$HOME/.env"
BASHRC_FILE="$HOME/.bashrc"

# Проверка, существует ли файл .env и загрузка переменных, если он существует
if [ -f "$ENV_FILE" ]; then
  echo -e "${B_GREEN}$ENV_FILE найден. Загружаем переменные...${NO_COLOR}"
  # Загружаем переменные из .env файла
  source "$ENV_FILE"
  echo -e "${B_GREEN}Переменные успешно загружены из .env файла.${NO_COLOR}"
else
  echo -e "${B_YELLOW}$ENV_FILE не найден. Выполним настройку переменных.${NO_COLOR}"
  echo

  # Ввод данных пользователя для настройки
  read -s -p "Введите пароль для Keyring: " KEYRING_PASSWORD
  echo
  echo -e "${B_CYAN}Выберите, что вводить:${NO_COLOR}"
  echo "1) ${B_GREEN} Имя кошелька${NO_COLOR}"
  echo "2) ${B_GREEN} Адрес кошелька${NO_COLOR}"
  read -p "${B_MAGENTA} Что выбираете? (1 или 2): ${NO_COLOR}" choice

  if [ "$choice" -eq 1 ]; then
    # Вводим имя кошелька
    read -p "${B_BLUE}Введите имя кошелька: ${NO_COLOR}" WALLET_NAME
    # Получаем адрес кошелька и валидатора на основе имени кошелька
    WALLET_ADDRESS=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_NAME" --bech acc -a)
    VALIDATOR_ADDRESS=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_NAME" --bech val -a)
  elif [ "$choice" -eq 2 ]; then
    # Вводим адрес кошелька
    read -p "${B_BLUE}Введите адрес кошелька: ${NO_COLOR}" WALLET_ADDRESS
    # Получаем имя кошелька и валидатора на основе адреса кошелька
    WALLET_NAME=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_ADDRESS" --output json | jq -r '.name')
    VALIDATOR_ADDRESS=$(printf "%s" "$KEYRING_PASSWORD" | 0gchaind keys show "$WALLET_NAME" --bech val -a)
  else
    echo -e "${B_RED}Неверный выбор. Пожалуйста, выберите 1 или 2.${NO_COLOR}"
    exit 1
  fi

  echo

  # Запрос на ввод Telegram переменных (с возможностью пропуска)
  echo -e "${B_CYAN}Если хотите, можете пропустить ввод данных для Telegram. Эти данные можно будет ввести при попытке включить мониторинг.${NO_COLOR}"
  read -p "${B_MAGENTA}Введите токен Telegram-бота (или нажмите Enter, чтобы пропустить): ${NO_COLOR}" TELEGRAM_BOT_TOKEN
  read -p "${B_MAGENTA}Введите Chat ID Telegram (или нажмите Enter, чтобы пропустить): ${NO_COLOR}" TELEGRAM_CHAT_ID

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

  echo -e "${B_GREEN}.env файл успешно создан с переменными окружения!${NO_COLOR}"
  echo
fi

# Проверка, существует ли уже команда для автоматической загрузки переменных в .bashrc
if ! grep -q "source \$HOME/.env" "$BASHRC_FILE"; then
  echo -e "${B_YELLOW}Добавляем автоматическую загрузку переменных из .env в .bashrc...${NO_COLOR}"
  # Добавляем команду в .bashrc, чтобы переменные автоматически загружались при каждом входе в систему
  echo -e "\n# Загрузка переменных окружения из .env\nif [ -f \"\$HOME/.env\" ]; then\n  source \"\$HOME/.env\"\nfi" >> "$BASHRC_FILE"
  echo -e "${B_GREEN}Команда для загрузки переменных добавлена в .bashrc.${NO_COLOR}"
  echo
else
  echo -e "${B_GREEN}Автоматическая загрузка переменных уже настроена в .bashrc.${NO_COLOR}"
  echo
fi

# Меню для управления валидатором
while true; do
  echo -e "${B_CYAN}========= 📋 Меню управления валидатором =========${NO_COLOR}"
  echo -e "${B_GREEN}1) 💰 Собрать комиссии и реварды валидатора${NO_COLOR}"
  echo -e "${B_GREEN}2) 💸 Собрать реварды со всех кошельков${NO_COLOR}"
  echo -e "${B_GREEN}3) 📥 Делегировать валидатору со всех кошельков${NO_COLOR}"
  echo -e "${B_GREEN}4) 🗳 Голосование${NO_COLOR}"
  echo -e "${B_RED}5) 🚪 Выход из тюрьмы (unjail)${NO_COLOR}"
  echo -e "${B_YELLOW}6) ✅ Включить мониторинг валидатора${NO_COLOR}"
  echo -e "${B_YELLOW}7) ⛔ Отключить мониторинг валидатора${NO_COLOR}"
  echo -e "${B_BLUE}8) ❌ Выход${NO_COLOR}"
  echo -e "${B_CYAN}==================================================${NO_COLOR}"
  echo

  read -p "${B_MAGENTA}Выберите пункт меню (1-8): ${NO_COLOR}" choice

  case $choice in
    1)
      echo -e "${B_GREEN}Собираем комиссии и реварды валидатора...${NO_COLOR}"
      # Здесь добавьте код для сбора комиссий и ревардов
      ;;
    2)
      echo -e "${B_GREEN}Собираем реварды со всех кошельков...${NO_COLOR}"
      # Здесь добавьте код для сбора ревардов со всех кошельков
      ;;
    3)
      echo -e "${B_GREEN}Делегируем валидатору со всех кошельков...${NO_COLOR}"
      # Здесь добавьте код для делегирования
      ;;
    4)
      echo -e "${B_GREEN}Переходим к голосованию...${NO_COLOR}"
      # Здесь добавьте код для голосования
      ;;
    5)
      echo -e "${B_RED}Выход из тюрьмы (unjail)...${NO_COLOR}"
      # Здесь добавьте код для выхода из тюрьмы (unjail)
      ;;
    6)
      # Включаем мониторинг валидатора
      if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
        echo -e "${B_YELLOW}Telegram настройки не были введены. Пожалуйста, введите их.${NO_COLOR}"
        read -p "${B_MAGENTA}Введите токен Telegram-бота: ${NO_COLOR}" TELEGRAM_BOT_TOKEN
        read -p "${B_MAGENTA}Введите Chat ID Telegram: ${NO_COLOR}" TELEGRAM_CHAT_ID

        # Сохраняем новые данные в .env
        echo "TELEGRAM_BOT_TOKEN=\"$TELEGRAM_BOT_TOKEN\"" >> "$ENV_FILE"
        echo "TELEGRAM_CHAT_ID=\"$TELEGRAM_CHAT_ID\"" >> "$ENV_FILE"
      fi
      echo -e "${B_GREEN}Включаем мониторинг валидатора...${NO_COLOR}"
      # Здесь добавьте код для включения мониторинга
      ;;
    7)
      echo -e "${B_YELLOW}Отключаем мониторинг валидатора...${NO_COLOR}"
      # Здесь добавьте код для отключения мониторинга
      ;;
    8)
      echo -e "${B_BLUE}Выход из программы...${NO_COLOR}"
      break  # Это заменяет exit 0 и не завершает сессию
      ;;
    *)
      echo -e "${B_RED}Неверный выбор, пожалуйста, выберите пункт от 1 до 8.${NO_COLOR}"
      ;;
  esac
done

