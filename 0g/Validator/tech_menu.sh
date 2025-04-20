#!/bin/bash

CONFIG_DIR="$HOME/.validator_config"
ENV_FILE="$CONFIG_DIR/env"
MONITOR_PIDS_FILE="$CONFIG_DIR/monitor_pids"
PROGRAM_DIR="$HOME/0g/Validator"
LOG_FILE="$CONFIG_DIR/install.log"
PROFILE_FILE="$HOME/.bash_profile"

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
  if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$PROFILE_FILE"; then
    echo 'export PATH="$HOME/bin:$PATH"' >> "$PROFILE_FILE"
    log "✅ Добавлен export PATH в $PROFILE_FILE."
  else
    log "ℹ️ export PATH уже присутствует в $PROFILE_FILE."
  fi

  if ! grep -q "source $ENV_FILE" "$PROFILE_FILE"; then
    echo "source $ENV_FILE" >> "$PROFILE_FILE"
    log "✅ Добавлен source $ENV_FILE в $PROFILE_FILE."
  else
    log "ℹ️ source $ENV_FILE уже присутствует в $PROFILE_FILE."
  fi

  if ! grep -q 'source ~/.bashrc' "$PROFILE_FILE"; then
    echo 'source ~/.bashrc' >> "$PROFILE_FILE"
    log "✅ Добавлен source ~/.bashrc в $PROFILE_FILE."
  else
    log "ℹ️ source ~/.bashrc уже присутствует в $PROFILE_FILE."
  fi

  export PATH="$HOME/bin:$PATH"
  hash -r
  log "🔁 Обновлён PATH и сброшен кэш команд."
}

remove_from_profile() {
  local pattern="$1"
  if grep -qF "$pattern" "$PROFILE_FILE"; then
    sed -i "\|$pattern|d" "$PROFILE_FILE"
    log "🧹 Удалена строка из .bash_profile по шаблону: $pattern"
  else
    log "ℹ️ Шаблон не найден в .bash_profile: $pattern"
  fi
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

  # Удаляем строки из .bash_profile
  remove_from_profile 'export PATH="$HOME/bin:$PATH"'
  remove_from_profile 'source ~/.validator_config/env'
  remove_from_profile 'source ~/.bashrc'

  # Удаляем директории и файл запуска
  rm -rf "$HOME/0g"
  rm -f "$HOME/bin/validator" && log "🗑️ Удалён скрипт запуска validator"
  rmdir "$HOME/bin" 2>/dev/null && log "🧹 Удалена пустая директория ~/bin"

  rm -rf "$CONFIG_DIR"

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

