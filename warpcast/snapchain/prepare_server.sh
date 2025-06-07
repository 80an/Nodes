#!/bin/bash

# Берем цвета
source <(wget -qO- 'https://raw.githubusercontent.com/CBzeek/Nodes/refs/heads/main/!tools/bash-colors.sh')
B_BLUE='\033[1;34m'   # Blue 
B_PURPLE='\033[0;35m' # Purple 
B_CYAN='\033[0;36m'   # Cyan

set -e

echo "📦 Обновляем пакеты и устанавливаем необходимые зависимости..."

sudo apt update

# Устанавливаем недостающие заголовки C и clang для bindgen/LLVM
sudo apt install -y \
  git curl build-essential cmake protobuf-compiler docker.io docker-compose make \
  pkg-config libssl-dev clang libc6-dev

# Запускаем и включаем Docker
sudo systemctl start docker
sudo systemctl enable docker

# Добавляем пользователя в группу docker (если не root — просто на всякий случай)
sudo usermod -aG docker $USER || true

# Устанавливаем grpcurl из релиза GitHub, если не найден
if ! command -v grpcurl &> /dev/null; then
  echo "🔌 grpcurl не найден, устанавливаем из релиза GitHub..."
  GRPCURL_VER=1.8.7
  curl -LO https://github.com/fullstorydev/grpcurl/releases/download/v${GRPCURL_VER}/grpcurl_${GRPCURL_VER}_linux_x86_64.tar.gz
  tar -xzf grpcurl_${GRPCURL_VER}_linux_x86_64.tar.gz
  sudo mv grpcurl /usr/local/bin/
  rm grpcurl_${GRPCURL_VER}_linux_x86_64.tar.gz
else
  echo "✅ grpcurl уже установлен."
fi

# Устанавливаем Rust и Cargo, если не установлены
if ! command -v rustc &> /dev/null || ! command -v cargo &> /dev/null; then
  echo "🦀 Rust и Cargo не найдены, устанавливаем..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
else
  echo "✅ Rust и Cargo уже установлены."
fi

# Обновляем Rust до последней стабильной версии
rustup update stable

echo
echo "🔍 Проверяем установленные компоненты..."

missing=()

check_cmd() {
  if ! command -v "$1" &> /dev/null; then
    missing+=("$1")
  else
    echo -e "${B_GREEN}✅ Найдено:${NO_COLOR} $1 ($(which $1))"
  fi
}

check_cmd rustc
check_cmd cargo
check_cmd grpcurl
check_cmd docker
check_cmd docker-compose
check_cmd protoc
check_cmd cmake
check_cmd git
check_cmd curl
check_cmd make
check_cmd pkg-config
check_cmd openssl
check_cmd clang

echo

if [ ${#missing[@]} -ne 0 ]; then
  echo -e "${B_RED}❌${NO_COLOR} Не установлены следующие обязательные пакеты/утилиты:"
  for cmd in "${missing[@]}"; do
    echo "  - $cmd"
  done
  echo
  echo "Пожалуйста, установите их и повторите запуск скрипта."
  exit 1
else
  echo -e "${B_YELLOW}🎉${NO_COLOR} Все необходимые пакеты установлены. Можно приступать к установке и запуску ноды."
fi

echo
echo -e "${B_RED}‼️${NO_COLOR} Если вы запускаетесь не из под root, то необходимо применить изменения группы docker, перезапустив SSH сессию или выполнив: newgrp docker"
echo
echo -e "${B_GREEN}Для тех, кто запускает с правами root, ничего больше делать не нужно.${NO_COLOR}"
