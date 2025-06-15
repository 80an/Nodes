#!/bin/bash
set -e

# Цвета
B_GREEN='\033[1;32m'
B_RED='\033[1;31m'
B_YELLOW='\033[1;33m'
NO_COLOR='\033[0m'

echo -e "${B_YELLOW}📦 Установка необходимых зависимостей...${NO_COLOR}"

sudo apt update && sudo apt install -y \
  curl git docker.io docker-compose

echo -e "${B_GREEN}✅ Пакеты установлены.${NO_COLOR}"

# Запускаем и включаем Docker
sudo systemctl enable docker
sudo systemctl start docker

# Добавляем текущего пользователя в группу docker (если не root)
if [ "$EUID" -ne 0 ]; then
  sudo usermod -aG docker $USER
  echo -e "${B_YELLOW}🔁 Пожалуйста, выйдите из SSH и зайдите снова или выполните: newgrp docker${NO_COLOR}"
fi

# Установка grpcurl (если нужен для взаимодействия с нодой)
if ! command -v grpcurl &> /dev/null; then
  echo "🔌 Устанавливаем grpcurl..."
  GRPCURL_VER=1.8.7
  curl -LO https://github.com/fullstorydev/grpcurl/releases/download/v${GRPCURL_VER}/grpcurl_${GRPCURL_VER}_linux_x86_64.tar.gz
  tar -xzf grpcurl_${GRPCURL_VER}_linux_x86_64.tar.gz
  sudo mv grpcurl /usr/local/bin/
  rm grpcurl_${GRPCURL_VER}_linux_x86_64.tar.gz
else
  echo -e "${B_GREEN}✅ grpcurl уже установлен.${NO_COLOR}"
fi

echo
echo -e "${B_GREEN}🎉 Готово! Теперь вы можете запускать snapchain через Docker.${NO_COLOR}"
echo
echo -e "👉 Используйте: ${B_YELLOW}docker pull farcasterxyz/snapchain${NO_COLOR}"
