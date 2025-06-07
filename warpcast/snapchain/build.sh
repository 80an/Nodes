#!/bin/bash
set -e

echo "⏳ Клонируем eth-signature-verifier..."
git clone https://github.com/CassOnMars/eth-signature-verifier.git
cd eth-signature-verifier
git checkout 8deb4a091982c345949dc66bf8684489d9f11889
cd ..

echo "⏳ Клонируем malachite..."
git clone https://github.com/informalsystems/malachite.git
cd malachite
git checkout 13bca14cd209d985c3adf101a02924acde8723a5
cd ..

echo "⏳ Клонируем snapchain и собираем..."
git clone https://github.com/farcasterxyz/snapchain.git
cd snapchain
cargo build

echo "✅ Snapchain собран успешно. Можно запускать ноду или тесты."
