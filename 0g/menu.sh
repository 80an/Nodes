#!/bin/bash

# Цвета
B_GREEN="\e[32m"
B_YELLOW="\e[33m"
B_RED="\e[31m"
NO_COLOR="\e[0m"

MONITOR_PID_FILE="/tmp/monitor_pid"

# Функция запуска мониторинга
start_monitoring() {
  if [ -f "$MONITOR_PID_FILE" ] && kill -0 $(cat "$MONITOR_PID_FILE") 2>/dev/null; then
    echo -e "${B_YELLOW}⚠️ Мониторинг уже запущен с PID $(cat $MONITOR_PID_FILE)${NO_COLOR}"
    return
  fi

  echo -e "${B_GREEN}▶️ Запуск мониторинга...${NO_COLOR}"
  bash -c "source <(wget -qO- 'https://raw.githubusercontent.com/80an/Nodes/refs/heads/main/0g/only_monitoring.sh')" &
  MONITOR_PID=$!
  echo $MONITOR_PID > "$MONITOR_PID_FILE"
  echo -e "${B_GREEN}✅ Мониторинг запущен с PID $MONITOR_PID${NO_COLOR}"
}

# Функция остановки мониторинга
stop_monitoring() {
  if [ -f "$MONITOR_PID_FILE" ]; then
    MONITOR_PID=$(cat "$MONITOR_PID_FILE")
    if kill -0 "$MONITOR_PID" 2>/dev/null; then
      kill "$MONITOR_PID"
      echo -e "${B_RED}⛔ Мониторинг остановлен (PID $MONITOR_PID)${NO_COLOR}"
      rm -f "$MONITOR_PID_FILE"
    else
      echo -e "${B_YELLOW}⚠️ Процесс мониторинга не найден. Удаляю PID-файл.${NO_COLOR}"
      rm -f "$MONITOR_PID_FILE"
    fi
  else
    echo -e "${B_RED}🚫 Мониторинг не запущен${NO_COLOR}"
  fi
}

# Функция проверки статуса
check_status() {
  if [ -f "$MONITOR_PID_FILE" ]; then
    MONITOR_PID=$(cat "$MONITOR_PID_FILE")
    if kill -0 "$MONITOR_PID" 2>/dev/null; then
      echo -e "${B_GREEN}✅ Мониторинг работает (PID $MONITOR_PID)${NO_COLOR}"
    else
      echo -e "${B_YELLOW}⚠️ Мониторинг неактивен, но PID-файл существует${NO_COLOR}"
    fi
  else
    echo -e "${B_RED}❌ Мониторинг не запущен${NO_COLOR}"
  fi
}

# Функция меню
menu() {
  echo
  echo -e "${B_YELLOW}========= 🛠 Меню управления мониторингом 0G =========${NO_COLOR}"
  echo -e "1) ▶️  Запустить мониторинг"
  echo -e "2) ⏹  Остановить мониторинг"
  echo -e "3) ℹ️  Проверить статус мониторинга"
  echo -e "4) ❌ Выход"
  echo -e "${B_YELLOW}======================================================${NO_COLOR}"
}

# Основной цикл меню
while true; do
  menu
  read -p "Выберите действие: " choice
  case $choice in
    1) start_monitoring ;;
    2) stop_monitoring ;;
    3) check_status ;;
    4)
      echo -e "${B_YELLOW}👋 Выход...${NO_COLOR}"
      break
      ;;
    *) echo -e "${B_RED}Неверный выбор. Повторите.${NO_COLOR}" ;;
  esac
done
