#!/bin/bash

# Выбор действия
echo "Выберите действие:"
echo "1. Изменить размер swap-файла"
echo "2. Удалить swap-файл"
read -p "Введите номер действия: " ACTION

case $ACTION in
  1)
    # 1️⃣ Отключите текущий swap-файл (если есть)
    echo "Отключение текущего swap-файла..."
    sudo swapoff -a

    # 2️⃣ Удалите старый swap-файл (если есть)
    echo "Удаление старого swap-файла..."
    sudo rm -f /swapfile

    # 3️⃣ Создайте новый swap-файл
    echo "Создание нового swap-файла..."
    read -p "Введите размер swap-файла в ГБ: " SWAP_SIZE
    sudo dd if=/dev/zero of=/swapfile bs=1M count=$((SWAP_SIZE * 1024))

    # 4️⃣ Задайте права на swap-файл
    echo "Задание прав на swap-файл..."
    sudo chmod 600 /swapfile

    # 5️⃣ Активизируйте swap-файл
    echo "Активизация swap-файла..."
    sudo mkswap /swapfile

    # 6️⃣ Включите swap-файл
    echo "Включение swap-файла..."
    sudo swapon /swapfile

    # 7️⃣ Проверьте, что swap активирован
    echo "Проверка активации swap..."
    sudo swapon --show

    # 8️⃣ Добавьте swap в автозагрузку
    echo "Добавление swap в автозагрузку..."
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

    # 9️⃣ Проверьте swap
    echo "Проверка swap..."
    free -h

    echo "Изменение размера swap-файла завершено!"
    ;;

  2)
    # Удалите swap-файл
    echo "Удаление swap-файла..."
    sudo swapoff -a
    sudo rm -f /swapfile

    # Удалите запись из fstab
    echo "Удаление записи из fstab..."
    sudo sed -i '/\/swapfile/d' /etc/fstab

    echo "Проверка swap..."
    free -h

    echo "Удаление swap-файла завершено!"
    ;;

  *)
    echo "Недопустимый выбор. Выход..."
    exit 1
    ;;
esac
