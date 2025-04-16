#!/bin/bash

CONFIG_DIR="$HOME/.validator_config"
ENV_FILE="$CONFIG_DIR/env"
MONITOR_PIDS_FILE="$CONFIG_DIR/monitor_pids"
PROGRAM_DIR="$HOME/0g/Validator"

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

ensure_bin_in_path() {
  if ! grep -Fxq "export PATH=\"$HOME/bin:\$PATH\"" "$HOME/.bashrc"; then
    echo "export PATH=\"$HOME/bin:\$PATH\"" >> "$HOME/.bashrc"
    echo "hash -r" >> "$HOME/.bashrc"
    export PATH="$HOME/bin:$PATH"
    hash -r
    echo "✅ Путь ~/bin добавлен в .bashrc и активирован."
  else
    export PATH="$HOME/bin:$PATH"
    hash -r
  fi
}

run_setup() {
  bash "$PROGRAM_DIR/setup_per.sh"
  # Добавил запуск
  echo "🚀 Запуск основного меню..."
  bash "$PROGRAM_DIR/menu_validator.sh"
  
  # После установки или обновления автоматически выполняем эти команды
  echo "Обновляем настройки PATH и сбрасываем кэш команд:"
  source ~/.bashrc
  hash -r
}

install_program() {
  echo "📦 Установка программы..."
  stop_monitoring
  rm -rf "$PROGRAM_DIR"
  mkdir -p "$HOME/0g"

  TMP_DIR=$(mktemp -d)
  git clone --depth=1 https://github.com/80an/Nodes "$TMP_DIR"

  rsync -a --exclude='tech_menu.sh' --exclude='README.md' "$TMP_DIR/0g/Validator/" "$PROGRAM_DIR/"
  rm -rf "$TMP_DIR"

  ensure_bin_in_path
  run_setup
}

update_program() {
  echo "🔄 Обновление программы..."
  stop_monitoring
  rm -rf "$PROGRAM_DIR"
  mkdir -p "$HOME/0g"

  TMP_DIR=$(mktemp -d)
  git clone --depth=1 https://github.com/80an/Nodes "$TMP_DIR"

  rsync -a --exclude='tech_menu.sh' --exclude='README.md' "$TMP_DIR/0g/Validator/" "$PROGRAM_DIR/"
  rm -rf "$TMP_DIR"

  ensure_bin_in_path
  run_setup
}

delete_program() {
  echo "🧹 Удаление программы..."
  stop_monitoring
  rm -rf "$HOME/0g" "$CONFIG_DIR"
  rm -f "$HOME/bin/validator"
  # sed -i '/export PATH="\$HOME\/bin:\$PATH"/d' "$HOME/.bashrc"
  sed -i '/export PATH=\\"\$HOME\/bin:\$PATH\\"/d' "$HOME/.bashrc"
  sed -i '/hash -r/d' "$HOME/.bashrc"
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

  read -p "Выберите пункт: " choice

  case $choice in
    1)
      install_program
      break
      ;;
    2)
      update_program
      break
      ;;
    3)
      delete_program
      break
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
