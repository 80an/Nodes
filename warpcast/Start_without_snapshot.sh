#!/bin/bash

# Переход в папку с нодой
cd ~/hubble || { echo "Не удалось перейти в директорию ~/hubble"; exit 1; }

# Остановка Hubble
echo "Остановка Hubble..."
./hubble.sh down || { echo "Не удалось остановить Hubble"; exit 1; }

# Редактирование файла docker-compose.yml
echo "Редактирование файла docker-compose.yml..."
if [ -f "docker-compose.yml" ]; then
    sed -i 's/${CATCHUP_SYNC_WITH_SNAPSHOT:-true}/${CATCHUP_SYNC_WITH_SNAPSHOT:-false}/' docker-compose.yml
else
    echo "Файл docker-compose.yml не найден!"
    exit 1
fi

# Запуск Hubble без обновления
echo "Запуск Hubble без обновления..."
./hubble.sh up || { echo "Не удалось запустить Hubble"; exit 1; }

echo "Процесс завершен."
