#!/bin/bash

# Запрашиваем у пользователя ввод Node ID
read -p "Введите Node ID: " NODE_ID

# Завершаем сессию screen с именем nexus
screen -S nexus -X quit

# Останавливаем контейнер Nexus
docker stop nexus

# Удаляем контейнер Nexus
docker rm nexus

# Обновляем образ Nexus CLI
docker pull nexusxyz/nexus-cli:latest

# Устанавливаем screen, если он еще не установлен
sudo apt install screen -y && screen -Rd nexus

# Сообщаем пользователю, что сессия запущена
echo "Сессия screen 'nexus' запущена. Для подключения используйте: screen -Rd nexus"
