#!/bin/bash

cd $HOME

#Ubuntu update and upgrade
print_header "Updating and Upgrading server..."
sudo apt update && sudo apt upgrade -y


#Install software
print_header "Installing dependencies to server..."
sudo apt install curl mc git jq screen lz4 build-essential htop zip unzip wget rsync snapd -y
sudo snap install yq
