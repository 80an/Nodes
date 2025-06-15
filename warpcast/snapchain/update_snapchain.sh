#!/bin/bash

set -e

REPO_DIR="$HOME/snapchain"
REPO_URL="https://github.com/farcasterxyz/snapchain.git"

B_GREEN='\033[1;32m'
B_RED='\033[1;31m'
NO_COLOR='\033[0m'

echo "📦 Обновление Snapchain..."

cd "$REPO_DIR"

# Получаем последнюю версию (тег)
latest_tag=$(git ls-remote --tags --refs "$REPO_URL" | awk -F/ '{print $NF}' | sort -V | tail -n 1)

if [ -z "$latest_tag" ]; then
  echo -e "${B_RED}❌ Не удалось получить последнюю версию.${NO_COLOR}"
  exit 1
fi

echo "🔖 Последний тег: $latest_tag"

# Проверим текущую версию
current_version=$(grep '^version' Cargo.toml | head -n1 | cut -d'"' -f2)
echo "📌 Текущая версия: $current_version"

if [ "$current_version" == "${latest_tag#v}" ]; then
  echo -e "${B_GREEN}✅ Уже установлена последняя версия.${NO_COLOR}"
  exit 0
fi

echo "🔄 Обновляем до версии $latest_tag..."

# Обновляем репозиторий и переключаемся
git fetch --all
git checkout "$latest_tag"

# Пересобираем бинарь
echo "🛠️  Сборка проекта..."
cargo build

# Обновляем docker
echo "🐳 Перезапуск docker compose..."
docker compose down
docker compose pull
docker compose up -d --build

echo -e "\n${B_GREEN}🎉 Обновление до версии $latest_tag завершено!${NO_COLOR}"
