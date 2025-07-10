#!/bin/bash

CRON_JOB="0 4 * * * /bin/bash -c \"bash <(wget -qO- 'https://raw.githubusercontent.com/80an/Nodes/refs/heads/main/nexus/upgrade.sh')\""
CRON_TMP=$(mktemp)

# Проверяем наличие cron и ставим, если нет
if ! command -v cron &> /dev/null && ! command -v crond &> /dev/null; then
  echo "cron не найден, устанавливаем..."
  sudo apt update && sudo apt install cron -y
  sudo systemctl enable cron
  sudo systemctl start cron
else
  echo "cron уже установлен"
fi

# Добавляем cron-задачу, если её ещё нет
crontab -l 2>/dev/null | grep -F "$CRON_JOB" >/dev/null
if [ $? -eq 0 ]; then
  echo "Задача уже в crontab"
else
  echo "Добавляем задачу в crontab"
  (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
fi

echo "Готово! Задание на обновление добавлено в cron на 4:00 утра."
