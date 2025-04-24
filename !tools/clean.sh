#!/bin/bash

echo -e "\n🚀 Начинаем очистку дискового пространства...\n"

# 1. Очистка docker: образы, контейнеры, volume и кэш
echo -e "\n🧼 Очистка Docker..."
docker system prune -af --volumes

# 2. Очистка старых Snap-пакетов
echo -e "\n🧹 Очистка старых Snap-версий..."
sudo snap list --all | awk '/disabled/{print $1, $2}' | while read snapname version; do
    echo "Удаляю $snapname (rev $version)"
    sudo snap remove "$snapname" --revision="$version"
done

# 3. Очистка apt
echo -e "\n📦 Очистка apt-кэша и неиспользуемых пакетов..."
sudo apt clean
sudo apt autoremove -y

# 4. Показываем размер основных директорий
echo -e "\n📊 Использование диска в корневом разделе:\n"
sudo du -sh /* 2>/dev/null | sort -hr | head -n 15

echo -e "\n✅ Очистка завершена.\n"
