#!/bin/bash

install_0g_validator() {
  # === Настройки по умолчанию ===
  NODE_NAME=${NODE_NAME:-"0g-node"}
  DATA_PATH=${DATA_PATH:-"$HOME/0g-data"}
  NODE_IP=${NODE_IP:-"$(curl -s ifconfig.me)"}
  PACKAGE_URL="https://github.com/0glabs/0gchain-NG/releases/download/v1.2.0/galileo-v1.2.0.tar.gz"

  echo "🔧 Установка ноды 0G | Node name: $NODE_NAME | Data path: $DATA_PATH | Node IP: $NODE_IP"

  # === Загрузка архива ===
  echo "⬇️  Загрузка пакета ноды..."
  wget -O galileo.tar.gz "$PACKAGE_URL"

  # === Распаковка ===
  echo "📦 Распаковка архива..."
  tar -xzvf galileo.tar.gz -C "$HOME"

  # === Копирование и права ===
  cd "$HOME/galileo" || exit 1
  echo "📁 Копирование конфигов..."
  mkdir -p "$DATA_PATH"
  cp -r 0g-home "$DATA_PATH"

  echo "🔐 Установка прав..."
  chmod +x ./bin/geth
  chmod +x ./bin/0gchaind

  # === Инициализация Geth ===
  echo "⚙️  Инициализация Geth..."
  ./bin/geth init --datadir "$DATA_PATH/0g-home/geth-home" ./genesis.json

  # === Инициализация 0gchaind ===
  echo "⚙️  Инициализация 0gchaind..."
  ./bin/0gchaind init "$NODE_NAME" --home "$DATA_PATH/tmp"

  # === Перемещение файлов ===
  echo "🚚 Копирование ключей..."
  cp "$DATA_PATH/tmp/data/priv_validator_state.json" "$DATA_PATH/0g-home/0gchaind-home/data/"
  cp "$DATA_PATH/tmp/config/node_key.json" "$DATA_PATH/0g-home/0gchaind-home/config/"
  cp "$DATA_PATH/tmp/config/priv_validator_key.json" "$DATA_PATH/0g-home/0gchaind-home/config/"
  rm -rf "$DATA_PATH/tmp"

  # === Запуск 0gchaind ===
  echo "🚀 Запуск 0gchaind..."
  nohup ./bin/0gchaind start \
    --rpc.laddr tcp://0.0.0.0:26657 \
    --chaincfg.chain-spec devnet \
    --chaincfg.kzg.trusted-setup-path=kzg-trusted-setup.json \
    --chaincfg.engine.jwt-secret-path=jwt-secret.hex \
    --chaincfg.kzg.implementation=crate-crypto/go-kzg-4844 \
    --chaincfg.block-store-service.enabled \
    --chaincfg.node-api.enabled \
    --chaincfg.node-api.logging \
    --chaincfg.node-api.address 0.0.0.0:3500 \
    --pruning=nothing \
    --home "$DATA_PATH/0g-home/0gchaind-home" \
    --p2p.seeds 85a9b9a1b7fa0969704db2bc37f7c100855a75d9@8.218.88.60:26656 \
    --p2p.external_address "$NODE_IP:26656" \
    > "$DATA_PATH/0g-home/log/0gchaind.log" 2>&1 &

  # === Запуск Geth ===
  echo "🚀 Запуск Geth..."
  nohup ./bin/geth --config geth-config.toml \
    --nat extip:"$NODE_IP" \
    --bootnodes enode://de7b86d8ac452b1413983049c20eafa2ea0851a3219c2cc12649b971c1677bd83fe24c5331e078471e52a94d95e8cde84cb9d866574fec957124e57ac6056699@8.218.88.60:30303 \
    --datadir "$DATA_PATH/0g-home/geth-home" \
    --networkid 16601 \
    > "$DATA_PATH/0g-home/log/geth.log" 2>&1 &

  # === Проверка ===
  echo "✅ Установка завершена. Проверка логов:"
  echo "------ geth.log (последние строки) ------"
  tail -n 10 "$DATA_PATH/0g-home/log/geth.log"
  echo "------ 0gchaind.log (последние строки) ------"
  tail -n 10 "$DATA_PATH/0g-home/log/0gchaind.log"
}

echo "✅ Функция install_0g_validator загружена. Запусти её:"
echo "   install_0g_validator"
echo
echo "👉 Или с переменными:"
echo "   NODE_NAME=my-node DATA_PATH=/data/0g install_0g_validator"
