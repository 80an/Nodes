#!/bin/bash

REPO_URL="https://github.com/80an/Nodes"
TARGET_DIR="$HOME/validator-tools"

show_menu() {
  clear
  echo "========= 📦 Установка скриптов 0G Validator ========="
  echo "1) 📥 Загрузить скрипт управления валидатором"
  echo "2) 🔄 Обновить скрипт (пока не реализовано)"
  echo "3) ❌ Удалить скрипт (пока не реализовано)"
  echo "4) 🚪 Выйти"
  echo "======================================================"
}

download_scripts() {
  echo "📥 Загрузка скриптов в $TARGET_DIR ..."
  mkdir -p "$TARGET_DIR"
  cd "$TARGET_DIR" || exit

  # Скачиваем архив репозитория
  wget -qO- "$REPO_URL/archive/refs/heads/main.tar.gz" | tar -xz --strip-components=2 Nodes-main/0g/Validator

  # Делаем исполняемыми все .sh-файлы
  find "$TARGET_DIR" -type f -name "*.sh" -exec chmod +x {} \;

  echo "✅ Скрипты загружены в $TARGET_DIR"
  echo
  read -p "Нажмите Enter для продолжения..."
}

while true; do
  show_menu
  read -p "Выберите действие: " choice
  case $choice in
    1)
      download_scripts
      ;;
    2)
      echo "🔄 Обновление скриптов (в разработке)"
      # Тут будет логика обновления скриптов с GitHub
      read -p "Нажмите Enter для продолжения..."
      ;;
    3)
      echo "❌ Удаление скриптов (в разработке)"
      # rm -rf "$TARGET_DIR"
      read -p "Нажмите Enter для продолжения..."
      ;;
    4)
      echo "🚪 Выход..."
      break
      ;;
    *)
      echo "❗ Неверный выбор. Повторите попытку."
      ;;
  esac
done
