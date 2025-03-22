#!/bin/bash

# Скрипт для установки и запуска ноды LayerEdge Light Node

set -e  # Остановка при ошибке

# 1. Установка необходимых зависимостей

# Установка Go
if ! command -v go &> /dev/null
then
    echo "Устанавливаем Go..."
    wget https://golang.org/dl/go1.23.1.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.23.1.linux-amd64.tar.gz
    rm go1.23.1.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=$HOME/go
    export PATH=$PATH:$GOPATH/bin
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    echo 'export GOPATH=$HOME/go' >> ~/.bashrc
    echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
    source ~/.bashrc
fi

echo "Go установлен: $(go version)"

# Установка Rust
if ! command -v rustc &> /dev/null
then
    echo "Устанавливаем Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
fi

echo "Rust установлен: $(rustc --version)"

# Установка Risc0 Toolchain
if ! command -v rzup &> /dev/null
then
    echo "Устанавливаем Risc0 Toolchain..."
    curl -L https://risczero.com/install | bash && source ~/.bashrc && rzup install
fi

echo "Risc0 Toolchain установлен."

# 2. Клонирование репозитория
if [ ! -d "light-node" ]; then
    echo "Клонируем репозиторий..."
    git clone https://github.com/Layer-Edge/light-node.git
fi
cd light-node

echo "Репозиторий клонирован."

# 3. Настройка переменных окружения
echo -n "Введите PRIVATE_KEY: "
read -s PRIVATE_KEY
echo
export PRIVATE_KEY
export GRPC_URL=grpc.testnet.layeredge.io:9090  >> ~/.bashrc
export CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709  >> ~/.bashrc
export ZK_PROVER_URL=http://127.0.0.1:3001  >> ~/.bashrc
export API_REQUEST_TIMEOUT=100  >> ~/.bashrc
export POINTS_API=http://127.0.0.1:8080  >> ~/.bashrc
source ~/.bashrc

cat > .env <<EOL
GRPC_URL=grpc.testnet.layeredge.io:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
# Альтернативный URL
# ZK_PROVER_URL=https://layeredge.mintair.xyz/
API_REQUEST_TIMEOUT=100
POINTS_API=http://127.0.0.1:8080
PRIVATE_KEY='$PRIVATE_KEY'
EOL

echo "Переменные окружения настроены."
