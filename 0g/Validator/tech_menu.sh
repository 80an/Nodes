#!/bin/bash

CONFIG_DIR="$HOME/.validator_config"
ENV_FILE="$CONFIG_DIR/env"
MONITOR_PIDS_FILE="$CONFIG_DIR/monitor_pids"
PROGRAM_DIR="$HOME/0g/Validator"
LOG_FILE="$CONFIG_DIR/install.log"

mkdir -p "$CONFIG_DIR"

# === Функции ===

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

stop_monitoring() {
  if [ -f "$MONITOR_PIDS_FILE" ]; then
    log "⛔ Останавливаем мониторинги..."
    while IFS= read -r pid; do
      if ps -p "$pid" > /dev/null 2>&1; then
        kill "$pid"
        log "🔻 Остановлен процесс с PID $pid"
      fi
    done < "$MONITOR_PIDS_FILE"
    rm -f "$MONITOR_PIDS_FILE"
    log "✅ Все мониторинги остановлены."
  else
    log "ℹ️ Нет активных процессов мониторинга."
  fi
}

ensure_bin_in_path() {
  local bashrc="$HOME/.bashrc"
  local profile="$HOME/.profile"

  for file in "$bashrc" "$profile"; do
    if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$file"; then
      echo 'export PATH="$HOME/bin:$PATH"' >> "$file"
      log "✅ Путь ~/bin добавлен в $file."
    else
      log "ℹ️ Путь ~/bin уже присутствует в $file."
    fi

    if [ "$file" = "$profile" ]; then
      if grep -q 'source ~/.bashrc' "$file"; then
        log "ℹ️ .bashrc уже подгружается из $file."
      else
        echo 'source ~/.bashrc' >> "$file"
        log "✅ Добавлен source ~/.bashrc в $file."
      fi
    fi

    if ! grep -q "source $ENV_FILE" "$file"; then
      echo "source $ENV_FILE" >> "$file"
      log "✅ Добавлен source $ENV_FILE в $file."
    else
      log "ℹ️ $ENV_FILE уже подгружается из $file."
    fi
  done

  export PATH="$HOME/bin:$PATH"
  hash -r
  log "🔁 Обновлён PATH и сброшен кэш команд."
}

run_setup() {
  bash "$PROGRAM_DIR/setup_per.sh" | tee -a "$LOG_FILE"
  log "🚀 Запуск основного меню..."
  source "$PROGRAM_DIR/menu_validator.sh"
}

install_program() {
  log "📦 Установка программы..."
  stop_monitoring
  rm -rf "$PROGRAM_DIR"
  mkdir -p "$HOME/0g"

  TMP_DIR=$(mktemp -d)
  git clone --depth=1 https://github.com/80an/Nodes "$TMP_DIR" | tee -a "$LOG_FILE"

  rsync -a --exclude='tech_menu.sh' --exclude='README.md' "$TMP_DIR/0g/Validator/" "$PROGRAM_DIR/" | tee -a "$LOG_FILE"
  rm -rf "$TMP_DIR"

  ensure_bin_in_path
  run_setup
}

update_program() {
  log "🔄 Обновление программы..."
  stop_monitoring
  rm -rf "$PROGRAM_DIR"
  mkdir -p "$HOME/0g"

  TMP_DIR=$(mktemp -d)
  git clone --depth=1 https://github.com/80an/Nodes "$TMP_DIR" | tee -a "$LOG_FILE"

  rsync -a --exclude='tech_menu.sh' --exclude='README.md' "$TMP_DIR/0g/Validator/" "$PROGRAM_DIR/" | tee -a "$LOG_FILE"
  rm -rf "$TMP_DIR"

  ensure_bin_in_path
  run_setup
}

delete_program() {
  log "🧹 Удаление программы..."
  stop_monitoring
  rm -rf "$HOME/0g" "$CONFIG_DIR"
  rm -f "$HOME/bin/validator"
  sed -i '/export PATH="$HOME\/bin:$PATH"/d' "$HOME/.bashrc"
  sed -i '/export PATH="$HOME\/bin:$PATH"/d' "$HOME/.profile"
  log "✅ Программа и все её данные удалены."
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
