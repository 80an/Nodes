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
export GRPC_URL=grpc.testnet.layeredge.io:9090
export CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
export ZK_PROVER_URL=http://127.0.0.1:3001
export API_REQUEST_TIMEOUT=100
export POINTS_API=http://127.0.0.1:8080

cat > .env <<EOL
GRPC_URL=grpc.testnet.layeredge.io:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
# Альтернативный URL
ZK_PROVER_URL=https://layeredge.mintair.xyz/
API_REQUEST_TIMEOUT=100
POINTS_API=http://127.0.0.1:8080
PRIVATE_KEY='$PRIVATE_KEY'
EOL

echo "Переменные окружения настроены."

# 4. Запуск Merkle-сервиса в screen-сессии
cd risc0-merkle-service
# Запускаем Merkle-сервис в скрытом режиме
screen -dmS layeredge_server bash -c 'cargo build && cargo run'

# Ожидание запуска Merkle-сервиса
echo "Ожидание запуска Merkle-сервиса..."
while true; do
    # Проверяем логи на наличие строки "Starting server on port 3001"
    if screen -S layeredge_server -X hardcopy /tmp/merkle-service.log && grep -q "Starting server on port 3001" /tmp/merkle-service.log; then
        sleep 5  # Пауза в 5 секунд после того, как сервер запустится
        break  # Прерываем цикл после успешного старта
    fi
    sleep 2  # Проверка каждую 2 секунды
    echo -n "."
done

echo "\nMerkle-сервис успешно запущен!"
# После завершения установки сервиса, отключаемся от screen
screen -d layeredge_server  # Оставляем screen активным, но выходим из него
cd ..

echo "Merkle-сервис запущен в screen-сессии. Для возврата: screen -r layeredge_server"

# 5. Компиляция и запуск Light Node в новом screen-сессии
echo "Запуск Light Node в screen-сессии..."
screen -S lightnode -L -Logfile lightnode.log bash -c 'go build && ./light-node'
screen -r lightnode

echo "LayerEdge Light Node запущена в screen-сессии!"
