#!/bin/bash
set -e

echo "Обновляем пакеты и устанавливаем необходимые зависимости..."

sudo apt update

sudo apt install -y git curl build-essential cmake protobuf-compiler docker.io docker-compose make

# Запускаем и включаем Docker
sudo systemctl start docker
sudo systemctl enable docker

# Добавляем пользователя в группу docker (для возможности запускать docker без sudo)
sudo usermod -aG docker $USER

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

echo "✅ Подготовка окружения завершена."
echo "‼️ Чтобы применились изменения группы docker, перезапустите SSH сессию или выполните: newgrp docker"
