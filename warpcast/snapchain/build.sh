#!/bin/bash
set -e

B_GREEN='\033[1;32m'
B_RED='\033[1;31m'
B_YELLOW='\033[1;33m'
NO_COLOR='\033[0m'

clone_or_update_repo() {
  local repo_url=$1
  local dir_name=$2
  local commit_hash=$3

  if [ -d "$dir_name/.git" ]; then
    echo "🔄 Обновляем репозиторий $dir_name..."
    git -C "$dir_name" fetch origin

    # Определим основную ветку (main или master)
    local branch=$(git -C "$dir_name" remote show origin | awk '/HEAD branch/ {print $NF}')
    
    # Переключаемся на основную ветку и пуллим
    git -C "$dir_name" checkout "$branch"
    git -C "$dir_name" pull origin "$branch"
  else
    echo "📦 Клонируем репозиторий $dir_name..."
    git clone "$repo_url" "$dir_name"
  fi

  git -C "$dir_name" checkout "$commit_hash"
}

echo "📁 Подготовка зависимостей..."

clone_or_update_repo "https://github.com/CassOnMars/eth-signature-verifier.git" "eth-signature-verifier" "8deb4a091982c345949dc66bf8684489d9f11889"
clone_or_update_repo "https://github.com/informalsystems/malachite.git" "malachite" "13bca14cd209d985c3adf101a02924acde8723a5"
clone_or_update_repo "https://github.com/farcasterxyz/snapchain.git" "snapchain" "main"

echo -e "\n${B_GREEN}✅ Все репозитории успешно клонированы или обновлены.${NO_COLOR}"

echo "🔨 Сборка snapchain..."
cd snapchain
cargo build

echo -e "\n${B_GREEN}🎉 Сборка завершена успешно!${NO_COLOR}"

