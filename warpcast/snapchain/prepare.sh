#!/bin/bash
set -e

echo "Обновляем пакеты и устанавливаем необходимые зависимости..."

sudo apt update

# Основные утилиты
sudo apt install -y git curl build-essential cmake protobuf-compiler grpcurl docker.io docker-compose make

# Запускаем и включаем Docker
sudo systemctl start docker
sudo systemctl enable docker

# Добавляем пользователя в группу docker (для возможности запускать docker без sudo)
sudo usermod -aG docker $USER

# Устанавливаем Rust (если нет)
if ! command -v rustc &> /dev/null || ! command -v cargo &> /dev/null; then
  echo "Rust и Cargo не найдены, устанавливаем..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
else
  echo "Rust и Cargo уже установлены."
fi

# Обновляем Rust до стабильной версии
rustup update stable

echo "✅ Подготовка окружения завершена."
echo "‼️ Чтобы применились изменения группы docker, перезапустите SSH сессию или выполните: newgrp docker"
