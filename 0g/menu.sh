#!/bin/bash

# Название процесса и URL скрипта мониторинга
MONITOR_PROCESS_NAME="only_monitoring.sh"
MONITOR_SOURCE_URL="https://raw.githubusercontent.com/80an/Nodes/refs/heads/main/0g/only_monitoring.sh"

# Функция запуска мониторинга
start_monitor() {
  read -p "Введите Telegram Bot Token: " TELEGRAM_BOT_TOKEN
  read -p "Введите Telegram Chat ID: " TELEGRAM_CHAT_ID

  echo "Запускаю мониторинг..."
  TELEGRAM_BOT_TOKEN="$TELEGRAM_BOT_TOKEN" TELEGRAM_CHAT_ID="$TELEGRAM_CHAT_ID" \
  bash -c "source <(wget -qO- '$MONITOR_SOURCE_URL')" > monitor.log 2>&1 &
  echo "Мониторинг запущен с PID $!"
}

# Функция остановки мониторинга
stop_monitor() {
  echo "Останавливаю мониторинг..."
  pkill -f "$MONITOR_SOURCE_URL"
  echo "Мониторинг остановлен."
}

# Функция перезапуска мониторинга с обновлением токена/ID
restart_monitor() {
  echo "Перезапускаю мониторинг..."
  stop_monitor
  sleep 1
  start_monitor
}

# Функция просмотра логов
show_logs() {
  if [ -f monitor.log ]; then
    echo "Последние 30 строк лога:"
    tail -n 30 monitor.log
  else
    echo "Файл логов не найден."
  fi
}

# Функция отображения меню
menu() {
  while true; do
    echo
    echo "===== Меню управления мониторингом 0G ====="
    echo "1) ▶️  Запустить мониторинг"
    echo "2) ⏹  Остановить мониторинг"
    echo "3) ℹ️  Проверить статус"
    echo "4) 📜 Показать последние логи"
    echo "5) 🔄 Перезапустить (смена токена/chat_id)"
    echo "0) ❌ Выйти"
    echo "==========================================="
    read -p "Выберите действие: " CHOICE

    case $CHOICE in
      1) start_monitor ;;
      2) stop_monitor ;;
      3)
        if pgrep -f "$MONITOR_SOURCE_URL" > /dev/null; then
          echo "Мониторинг активен ✅"
        else
          echo "Мониторинг не запущен ❌"
        fi
        ;;
      4) show_logs ;;
      5) restart_monitor ;;
      0) echo "Выход..."; break ;;
      *) echo "Неверный выбор, попробуйте снова." ;;
    esac
  done
}

# Запуск меню
menu
