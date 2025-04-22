#!/bin/bash

# Import Colors
source <(wget -qO- 'https://raw.githubusercontent.com/CBzeek/Nodes/refs/heads/main/!tools/bash-colors.sh')

cd $HOME

#Ubuntu update and upgrade
print_header "Обновляем и подготавливаем сервер к работе..."
sudo apt update && sudo apt upgrade -y


#Install software
print_header "Устанавливаем необходимые пакеты на сервер..."
sudo apt install curl mc git jq screen lz4 build-essential htop zip unzip wget rsync snapd -y
sudo snap install yq
