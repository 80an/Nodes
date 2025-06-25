#!/bin/bash

install_0g_validator() {
  NODE_NAME=${NODE_NAME:-"0g-node"}
  DATA_PATH=${DATA_PATH:-"$HOME/0g-data"}
  NODE_IP=${NODE_IP:-"$(curl -s ifconfig.me)"}
  PACKAGE_URL="https://github.com/0glabs/0gchain-NG/releases/download/v1.2.0/galileo-v1.2.0.tar.gz"

  echo "🔧 Установка ноды 0G | Node name: $NODE_NAME | Data path: $DATA_PATH | Node IP: $NODE_IP"

  echo "⬇️  Загрузка пакета ноды..."
  wget -O galileo.tar.gz "$PACKAGE_URL" || return 1

  echo "📦 Распаковка архива..."
  tar -xzvf galileo.tar.gz -C "$HOME" || return 1

  WORKDIR=$(find "$HOME" -maxdepth 1 -type d -name "galileo-v*" | sort | tail -n1)
  if [[ ! -d "$WORKDIR" ]]; then
    echo "❌ Не найдена рабочая директория"
    return 1
  fi

  echo "📁 Копирование конфигов..."
  mkdir -p "$DATA_PATH"
  cp -r "$WORKDIR/0g-home" "$DATA_PATH" || return 1

  echo "🔐 Установка прав..."
  chmod +x "$WORKDIR/bin/geth"
  chmod +x "$WORKDIR/bin/0gchaind"

  echo "⚙️  Инициализация Geth..."
  "$WORKDIR/bin/geth" init --datadir "$DATA_PATH/0g-home/geth-home" "$WORKDIR/genesis.json"

  echo "⚙️  Инициализация 0gchaind..."
  "$WORKDIR/bin/0gchaind" init "$NODE_NAME" --home "$DATA_PATH/tmp"

  echo "🚚 Копирование ключей..."
  cp "$DATA_PATH/tmp/data/priv_validator_state.json" "$DATA_PATH/0g-home/0gchaind-home/data/"
  cp "$DATA_PATH/tmp/config/node_key.json" "$DATA_PATH/0g-home/0gchaind-home/config/"
  cp "$DATA_PATH/tmp/config/priv_validator_key.json" "$DATA_PATH/0g-home/0gchaind-home/config/"
  rm -rf "$DATA_PATH/tmp"

  echo "🚀 Запуск 0gchaind..."
  nohup "$WORKDIR/bin/0gchaind" start \
    --rpc.laddr tcp://0.0.0.0:26657 \
    --chaincfg.chain-spec devnet \
    --chaincfg.kzg.trusted-setup-path="$WORKDIR/kzg-trusted-setup.json" \
    --chaincfg.engine.jwt-secret-path="$WORKDIR/jwt-secret.hex" \
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

  echo "🚀 Запуск Geth..."
  nohup "$WORKDIR/bin/geth" --config "$WORKDIR/geth-config.toml" \
    --nat extip:"$NODE_IP" \
    --bootnodes enode://de7b86d8ac452b1413983049c20eafa2ea0851a3219c2cc12649b971c1677bd83fe24c5331e078471e52a94d95e8cde84cb9d866574fec957124e57ac6056699@8.218.88.60:30303 \
    --datadir "$DATA_PATH/0g-home/geth-home" \
    --networkid 16601 \
    > "$DATA_PATH/0g-home/log/geth.log" 2>&1 &

  echo "✅ Установка завершена. Проверка логов:"
  tail -n 10 "$DATA_PATH/0g-home/log/0gchaind.log"
  tail -n 10 "$DATA_PATH/0g-home/log/geth.log"
}

echo "✅ Функция install_0g_validator загружена. Запусти её:"
echo "   install_0g_validator"
echo
echo "👉 Или с переменными:"
echo "   NODE_NAME=my-node DATA_PATH=/mnt/0g install_0g_validator"
