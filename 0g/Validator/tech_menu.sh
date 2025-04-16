#!/bin/bash

CONFIG_DIR="$HOME/.validator_config"
ENV_FILE="$CONFIG_DIR/env"
MONITOR_PIDS_FILE="$CONFIG_DIR/monitor_pids"
PROGRAM_DIR="$HOME/0g/Validator"
NODES_REPO_DIR="$HOME/0g/Nodes"

mkdir -p "$CONFIG_DIR"

# === Функции ===

stop_monitoring() {
  if [ -f "$MONITOR_PIDS_FILE" ]; then
    echo "⛔ Останавливаем мониторинги..."
    while IFS= read -r pid; do
      if ps -p "$pid" > /dev/null 2>&1; then
        kill "$pid"
        echo "🔻 Остановлен процесс с PID $pid"
      fi
    done < "$MONITOR_PIDS_FILE"
    rm -f "$MONITOR_PIDS_FILE"
    echo "✅ Все мониторинги остановлены."
  else
    echo "ℹ️ Нет активных процессов мониторинга."
  fi
}

run_setup() {
  bash "$PROGRAM_DIR/setup_per.sh"
}

install_program() {
  echo "📦 Установка программы..."
  stop_monitoring
  rm -rf "$PROGRAM_DIR"
  mkdir -p "$HOME/0g"
  git clone --depth=1 https://github.com/80an/Nodes "$NODES_REPO_DIR"
  rsync -a --exclude='tech_menu.sh' "$NODES_REPO_DIR/0g/Validator/" "$PROGRAM_DIR/"
  run_setup
}

update_program() {
  echo "🔄 Обновление программы..."
  stop_monitoring
  rm -rf "$PROGRAM_DIR"
  mkdir -p "$HOME/0g"
  git clone --depth=1 https://github.com/80an/Nodes "$NODES_REPO_DIR"
  rsync -a --exclude='tech_menu.sh' "$NODES_REPO_DIR/0g/Validator/" "$PROGRAM_DIR/"
  run_setup
}

delete_program() {
  echo "🧹 Удаление программы..."
  stop_monitoring
  rm -rf "$PROGRAM_DIR" "$CONFIG_DIR"
  rm -f "$HOME/bin/validator"
  sed -i '/export PATH="\$HOME\/bin:\$PATH"/d' "$HOME/.bashrc"
  echo "✅ Программа и все её данные удалены."
}

# === Меню ===

while true; do
  echo ""
  echo "🛠️  Техническое меню"
  echo "========================="
  echo "1) 📥 Установить программу"
  echo "2) 🔄 Обновить скрипты"
  echo "3) 🧹 Удалить программу полностью"
  echo "4) 🚪 Выйти в консоль"
  echo "========================="

  read -p "Выберите пункт: "

  case $choice in
    1)
      install_program
      ;;
    2)
      update_program
      ;;
    3)
      delete_program
      ;;
    4)
      echo "👋 Возврат в консоль."
      break
      ;;
    *)
      echo "❌ Неверный выбор. Попробуйте снова."
      ;;
  esac

done
