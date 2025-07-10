#!/bin/bash

# Запрашиваем у пользователя ввод Node ID
read -p "Введите Node ID: " NODE_ID

# Подсказка для выбора max-threads
echo ""
echo "💡 Если сервер мощный, то можно попробовать фармить в несколько потоков."
echo "Рекомендации по параметру --max-threads:"
echo "🖥  4 CPU / 8 GB RAM    → --max-threads 4"
echo "🖥  8 CPU / 16 GB RAM   → --max-threads 8"
echo "📉 Если нода отключается — уменьшите значение этого параметра."
echo ""

# Запрос значения max-threads
read -p "Введите количество потоков (--max-threads): " MAX_THREADS

# Завершаем предыдущую сессию screen с именем nexus, если она есть
screen -S nexus -X quit

# Останавливаем и удаляем контейнер Nexus, если он существует
docker stop nexus 2>/dev/null
docker rm nexus 2>/dev/null

# Обновляем образ Nexus CLI
docker pull nexusxyz/nexus-cli:latest

# Устанавливаем screen, если он не установлен
if ! command -v screen &> /dev/null; then
  sudo apt update && sudo apt install screen -y
fi

# Запускаем новую screen-сессию с именем nexus и выполняем запуск контейнера внутри неё
screen -dmS nexus bash -c "docker run -it --init --name nexus nexusxyz/nexus-cli:latest start --node-id $NODE_ID --max-threads $MAX_THREADS"

# Вывод версии установленного Nexus CLI
echo ""
echo "🔍 Установленная версия Nexus CLI:"
docker run --rm nexusxyz/nexus-cli:latest --version

# Сообщаем пользователю, что сессия запущена
echo ""
echo "✅ Сессия screen 'nexus' запущена."
echo "🔧 Для подключения: screen -Rd nexus"
