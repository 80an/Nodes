#!/bin/bash
PROJECT_NAME="0G"

# Переменные
GITHUB_API_URL="https://api.github.com/repos/0glabs/0g-chain/releases/latest"
RELEASES_URL="https://github.com/0glabs/0g-chain/releases/download"

# Получение последней версии
echo ""
echo -e "\e[1m\e[32m###########################################################################################"
echo -e "\e[1m\e[32m### Fetching latest $PROJECT_NAME node version... \e[0m" && sleep 1
echo ""

LATEST_VERSION=$(curl -s $GITHUB_API_URL | jq -r '.tag_name')
if [ -z "$LATEST_VERSION" ]; then
    echo -e "\e[1m\e[31mFailed to fetch the latest version. Please check your internet connection or GitHub API.\e[0m"
    exit 1
fi
echo -e "\e[1m\e[32mLatest version found: $LATEST_VERSION\e[0m"

# Остановка ноды
echo ""
echo -e "\e[1m\e[32m###########################################################################################"
echo -e "\e[1m\e[32m### Stopping $PROJECT_NAME node... \e[0m" && sleep 1
echo ""
sudo systemctl stop ogd

# Резервное копирование
echo ""
echo -e "\e[1m\e[32m###########################################################################################"
echo -e "\e[1m\e[32m### Backing up $PROJECT_NAME node configuration files... \e[0m" && sleep 1
echo ""
rm -rf $HOME/backup-update
mkdir -p $HOME/backup-update/config
cp $HOME/.0gchain/config/priv_validator_key.json $HOME/backup-update/config
cp -r $HOME/.0gchain/keyring-test $HOME/backup-update/keyring-test || true
cp -r $HOME/.0gchain/* $HOME/backup-update || true

# Удаление старого бинарника
echo ""
echo -e "\e[1m\e[32m###########################################################################################"
echo -e "\e[1m\e[32m### Removing old binary... \e[0m" && sleep 1
echo ""
rm -f 0gchaind-linux-v*

# Загрузка последнего релиза
echo ""
echo -e "\e[1m\e[32m###########################################################################################"
echo -e "\e[1m\e[32m### Downloading and installing the latest version ($LATEST_VERSION)... \e[0m" && sleep 1
echo ""
wget $RELEASES_URL/$LATEST_VERSION/0gchaind-linux-$LATEST_VERSION -O 0gchaind
sudo chmod +x 0gchaind
sudo mv 0gchaind $(which 0gchaind)

# Проверка версии
echo ""
echo -e "\e[1m\e[32m###########################################################################################"
echo -e "\e[1m\e[32m### Verifying installed version... \e[0m" && sleep 1
echo ""
INSTALLED_VERSION=$(0gchaind version)
echo -e "\e[1m\e[32mInstalled version: $INSTALLED_VERSION\e[0m"

# Перезапуск ноды
echo ""
echo -e "\e[1m\e[32m###########################################################################################"
echo -e "\e[1m\e[32m### Restarting $PROJECT_NAME node... \e[0m" && sleep 1
echo ""
sudo systemctl restart ogd

# Завершение
echo ""
echo -e "\e[1m\e[32m###########################################################################################"
echo -e "\e[1m\e[32m### Update complete. Node is running the latest version: $INSTALLED_VERSION\e[0m"
echo ""
