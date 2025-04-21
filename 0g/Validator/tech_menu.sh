#!/bin/bash

CONFIG_DIR="$HOME/.validator_config"
ENV_FILE="$CONFIG_DIR/env"
MONITOR_PIDS_FILE="$CONFIG_DIR/monitor_pids"
PROGRAM_DIR="$HOME/0g/Validator"
PROFILE_FILE="$HOME/.bash_profile"

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
  if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$PROFILE_FILE"; then
    echo 'export PATH="$HOME/bin:$PATH"' >> "$PROFILE_FILE"
    echo "✅ Добавлен export PATH в $PROFILE_FILE."
  else
    echo "ℹ️ export PATH уже присутствует в $PROFILE_FILE."
  fi

  if ! grep -q "source $ENV_FILE" "$PROFILE_FILE"; then
    echo "source $ENV_FILE" >> "$PROFILE_FILE"
    echo "✅ Добавлен source $ENV_FILE в $PROFILE_FILE."
  else
    echo "ℹ️ source $ENV_FILE уже присутствует в $PROFILE_FILE."
  fi

  if ! grep -q 'source ~/.bashrc' "$PROFILE_FILE"; then
    echo 'source ~/.bashrc' >> "$PROFILE_FILE"
    echo "✅ Добавлен source ~/.bashrc в $PROFILE_FILE."
  else
    echo "ℹ️ source ~/.bashrc уже присутствует в $PROFILE_FILE."
  fi

  export PATH="$HOME/bin:$PATH"
  hash -r
  echo "🔁 Обновлён PATH и сброшен кэш команд."
}

remove_from_profile() {
  local pattern="$1"
  if grep -qF "$pattern" "$PROFILE_FILE"; then
    sed -i "\|$pattern|d" "$PROFILE_FILE"
    echo "🧹 Удалена строка из .bash_profile по шаблону: $pattern"
  else
    echo "ℹ️ Шаблон не найден в .bash_profile: $pattern"
  fi
}

run_setup() {
  bash "$PROGRAM_DIR/setup_per.sh"
  echo "🚀 Запуск основного меню..."
  source "$PROGRAM_DIR/menu_validator.sh"
}

manage_installation() {
  if [ -d "$PROGRAM_DIR" ]; then
    echo "🔄 Обновление программы..."
  else
    echo "📦 Установка программы..."
  fi

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

  remove_from_profile 'export PATH="$HOME/bin:$PATH"'
  remove_from_profile 'source ~/.validator_config/env'
  remove_from_profile 'source ~/.bashrc'

  rm -rf "$HOME/0g"
  rm -f "$HOME/bin/validator" && echo "🗑️ Удалён скрипт запуска validator"
  rmdir "$HOME/bin" 2>/dev/null && echo "🧹 Удалена пустая директория ~/bin"

  rm -rf "$CONFIG_DIR"

  echo "✅ Программа и все её данные удалены."
}

# === Меню ===

while true; do
  echo ""
  echo "🛠️  Техническое меню"
  echo "=============================="
  echo "1) 💾 Установка / обновление программы"
  echo "2) 🧹 Удалить программу полностью"
  echo "3) 🚪 Выйти в консоль"
  echo "=============================="

  read -p "Выберите пункт: " choice

  case $choice in
    1)
      manage_installation
      break
      ;;
    2)
      delete_program
      break
      ;;
    3)
      echo "👋 Возврат в консоль."
      break
      ;;
    *)
      echo "❌ Неверный выбор. Попробуйте снова."
      ;;
  esac
done
