#!/bin/bash
set -e

echo "Обновляем пакеты и устанавливаем необходимые зависимости..."

sudo apt update

sudo apt install -y git curl build-essential cmake protobuf-compiler docker.io docker-compose make

# Запускаем и включаем Docker
sudo systemctl start docker
sudo systemctl enable docker

# Добавляем пользователя в группу docker (если не root — просто на всякий случай)
sudo usermod -aG docker $USER || true

# Устанавливаем grpcurl из релиза GitHub, если не найден
if ! command -v grpcurl &> /dev/null; then
  echo "grpcurl не найден, устанавливаем из релиза GitHub..."
  GRPCURL_VER=1.8.7
  curl -LO https://github.com/fullstorydev/grpcurl/releases/download/v${GRPCURL_VER}/grpcurl_${GRPCURL_VER}_linux_x86_64.tar.gz
  tar -xzf grpcurl_${GRPCURL_VER}_linux_x86_64.tar.gz
  sudo mv grpcurl /usr/local/bin/
  rm grpcurl_${GRPCURL_VER}_linux_x86_64.tar.gz
else
  echo "grpcurl уже установлен."
fi

# Устанавливаем Rust и Cargo, если не установлены
if ! command -v rustc &> /dev/null || ! command -v cargo &> /dev/null; then
  echo "Rust и Cargo не найдены, устанавливаем..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
else
  echo "Rust и Cargo уже установлены."
fi

# Обновляем Rust до последней стабильной версии
rustup update stable

echo
echo "Проверяем установленные компоненты..."

missing=()

check_cmd() {
  if ! command -v "$1" &> /dev/null; then
    missing+=("$1")
  else
    echo "✅ Найдено: $1 ($(which $1))"
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

echo

if [ ${#missing[@]} -ne 0 ]; then
  echo "❌ Не установлены следующие обязательные пакеты/утилиты:"
  for cmd in "${missing[@]}"; do
    echo "  - $cmd"
  done
  echo
  echo "Пожалуйста, установите их и повторите запуск скрипта."
  exit 1
else
  echo "🎉 Все необходимые пакеты установлены. Можно приступать к установке и запуску ноды."
fi

echo
echo "‼️ Чтобы применились изменения группы docker, перезапустите SSH сессию или выполните: newgrp docker"

