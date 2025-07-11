#!/bin/bash

# Файл для хранения переменных
VARS_FILE="/root/.nexus_vars"

# === 1. Ввод переменных, если их ещё нет ===
if [[ ! -f "$VARS_FILE" ]]; then
  read -p "Введите Node ID: " NODE_ID
  echo ""
  echo "💡 Если сервер мощный, то можно попробовать фармить в несколько потоков."
  echo "Рекомендации по параметру --max-threads:"
  echo "🖥  4 CPU / 8 GB RAM    → --max-threads 4"
  echo "🖥  8 CPU / 16 GB RAM   → --max-threads 8"
  echo "📉 Если нода отключается — уменьшите значение этого параметра."
  echo ""
  read -p "Введите количество потоков (--max-threads): " MAX_THREADS

  echo "NODE_ID=$NODE_ID" > "$VARS_FILE"
  echo "MAX_THREADS=$MAX_THREADS" >> "$VARS_FILE"
else
  source "$VARS_FILE"
fi

# === 2. Получаем текущую и новую версии ===
LOCAL_VERSION=$(docker run --rm nexusxyz/nexus-cli:latest --version 2>/dev/null)
docker pull nexusxyz/nexus-cli:latest > /dev/null
REMOTE_VERSION=$(docker run --rm nexusxyz/nexus-cli:latest --version 2>/dev/null)

echo ""
echo "🔍 Текущая версия: $LOCAL_VERSION"
echo "🌐 Последняя версия: $REMOTE_VERSION"

# === 3. Если версия отличается, перезапускаем контейнер ===
if [[ "$LOCAL_VERSION" != "$REMOTE_VERSION" ]]; then
  echo "🚀 Найдена новая версия. Обновляем и перезапускаем..."

  screen -S nexus -X quit 2>/dev/null
  docker stop nexus 2>/dev/null
  docker rm nexus 2>/dev/null

  # Устанавливаем screen, если не установлен
  if ! command -v screen &> /dev/null; then
    sudo apt update && sudo apt install screen -y
  fi

  # Запускаем контейнер в новой screen-сессии
  screen -dmS nexus bash -c "docker run --init --name nexus nexusxyz/nexus-cli:latest start --node-id $NODE_ID --max-threads $MAX_THREADS"

  echo ""
  echo "✅ Обновлённая сессия 'nexus' запущена."
else
  echo "✅ Установлена последняя версия. Обновление не требуется."
fi

echo ""
echo "🔧 Для подключения: screen -Rd nexus"
