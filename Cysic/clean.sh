#!/bin/bash

echo "[*] Завершение screen-сессии..."
screen -S cysic-verifier -X quit 2>/dev/null

echo "[*] Удаление директорий и скриптов..."
rm -rf ~/cysic-verifier ~/.cysic ~/setup_linux.sh /root/setup_linux.sh /root/cysic-verifier

echo "[*] Очистка автозапуска в /etc/rc.local..."
if [ -f /etc/rc.local ]; then
  sed -i '/cysic\|verifier/d' /etc/rc.local
  chmod -x /etc/rc.local
fi

echo "[*] Очистка ~/.bashrc ~/.profile ..."
sed -i '/cysic\|verifier/d' ~/.bashrc ~/.profile 2>/dev/null

echo "[*] Проверка остаточных процессов:"
ps aux | grep verifier | grep -v grep

echo "[✔] Очистка завершена. Рекомендуется перезагрузка: sudo reboot"
