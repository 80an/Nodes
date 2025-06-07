#!/bin/bash
set -e

# Берем цвета
source <(wget -qO- 'https://raw.githubusercontent.com/CBzeek/Nodes/refs/heads/main/!tools/bash-colors.sh')

# Функция клонирования или обновления репозитория
clone_or_update_repo() {
  local repo_url=$1
  local dir_name=$2
  local commit_hash=$3
  local default_branch=$4

  if [ -d "$dir_name/.git" ]; then
    echo "🔄 Обновляем репозиторий $dir_name..."
    git -C "$dir_name" fetch --all
    git -C "$dir_name" checkout "$default_branch"
    git -C "$dir_name" pull --rebase
    git -C "$dir_name" checkout "$commit_hash"
  else
    echo "📦 Клонируем репозиторий $dir_name..."
    git clone "$repo_url" "$dir_name"
    git -C "$dir_name" checkout "$commit_hash"
  fi
}

echo "📁 Подготовка зависимостей..."

clone_or_update_repo "https://github.com/CassOnMars/eth-signature-verifier.git" "eth-signature-verifier" "8deb4a091982c345949dc66bf8684489d9f11889" "main"
clone_or_update_repo "https://github.com/informalsystems/malachite.git" "malachite" "13bca14cd209d985c3adf101a02924acde8723a5" "main"
clone_or_update_repo "https://github.com/farcasterxyz/snapchain.git" "snapchain" "main" "main"

echo -e "\n${B_GREEN}✅ Все репозитории успешно клонированы или обновлены.${NO_COLOR}"

echo "🔨 Сборка snapchain..."
cd snapchain
cargo build

echo -e "\n${B_GREEN}🎉 Сборка завершена успешно!${NO_COLOR}"
