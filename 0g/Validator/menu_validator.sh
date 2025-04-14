#!/bin/bash

# Загружаем и выполняем синхронизацию ключей
source <(wget -qO- 'https://raw.githubusercontent.com/80an/Nodes/refs/heads/Punkty-menu/0g/Validator/key_sync.sh')
sync_keys_from_os_to_file

# Файл для хранения переменных окружения
ENV_FILE="$HOME/.validator_env"

# Меню для управления валидатором
while true; do
  echo
  echo "========= 📋 Меню управления валидатором ========="
  echo "1) 💰 Забрать комиссии и реварды валидатора"
  echo "2) 💸 Забрать все реварды со всех кошельков"
  echo "3) 📥 Делегировать со всех кошельков в своего валидатора"
  echo "4) 🗳 Голосование по пропозалу"
  echo "5) 🚪 Вызволить из тюрьмы"
  echo "6) ✅ Мониторинг валидатора"
  echo "7) 📜 Мониторинг пропозалов"
  echo "8) ❌ Выход"
  echo "=================================================="
  echo

  read -p "Выберите пункт меню (1-8): " choice

    case $choice in
    1)
      echo "💰 Забрать комиссии и реварды валидатора"
      # Команда для снятия наград и комиссий
      printf "%s" "$KEYRING_PASSWORD" | 0gchaind tx distribution withdraw-rewards "$VALIDATOR_ADDRESS" \
      --chain-id="zgtendermint_16600-2" \
      --from "$WALLET_NAME" \
      --commission \
      --gas=auto \
      --gas-prices 0.003ua0gi \
      --gas-adjustment=1.4 \
      -y
      ;;
    2)
      echo "💸 Забрать все реварды со всех кошельков"
      # Здесь нужно перечислить все адреса и выполнить команду withdraw-rewards для каждого
      source <(wget -qO- 'https://raw.githubusercontent.com/80an/Nodes/refs/heads/Punkty-menu/0g/Validator/all_reward.sh')
      ;;
    3)
      echo "📥 Делегировать со всех кошельков в своего валидатора"
      # Аналогично, цикл по адресам, делегирование оставшихся средств
      source <(wget -qO- 'https://raw.githubusercontent.com/80an/Nodes/refs/heads/Punkty-menu/0g/Validator/all_delegation.sh')
      ;;
    4)
      echo "🗳 Голосование по пропозалу"
      read -p "Введите номер пропозала: " proposal
      read -p "Введите ваш голос (yes/no/abstain/no_with_veto): " vote
      # $BINARY tx gov vote $proposal $vote --from $WALLET_NAME --chain-id $CHAIN_ID --fees 5000$DENOM -y
      ;;
    5)
      echo "🚪 Вызволить из тюрьмы"
       printf "%s\n" "$KEYRING_PASSWORD" | 0gchaind tx slashing unjail \
       --from $WALLET_NAME \
       --chain-id zgtendermint_16600-2 \
       --gas=auto \
       --gas-prices 0.003ua0gi \
       --gas-adjustment=1.6 \
       -y
      ;;
    6)
      while true; do
        echo
        echo "=== ✅ Подменю мониторинга валидатора ==="
        echo "1) ▶️ Включить мониторинг"
        echo "2) 📊 Состояние мониторинга"
        echo "3) ⏹ Отключить мониторинг"
        echo "4) 🔙 Вернуться в главное меню"
        echo "========================================="
        read -p "Выберите действие (1-4): " subchoice

        case $subchoice in
          1)
            echo "▶️ Включаем мониторинг валидатора..."
            # Пример: запуск мониторинга как systemd-сервис или screen/tmux
            ;;
          2)
            echo "📊 Проверяем статус мониторинга валидатора..."
            # Пример: проверка состояния процесса или сервиса
            ;;
          3)
            echo "⛔ Останавливаем мониторинг валидатора..."
            # Пример: остановка мониторинга
            ;;
          4)
            echo "🔙 Возвращаемся в главное меню..."
            break
            ;;
          *)
            echo "🚫 Неверный выбор, пожалуйста, выберите от 1 до 4."
            ;;
        esac
      done
      ;;
    7)
      while true; do
        echo
        echo "=== 📜 Подменю мониторинга пропозалов ==="
        echo "1) ▶️ Включить мониторинг"
        echo "2) 📊 Состояние мониторинга"
        echo "3) ⏹ Отключить мониторинг"
        echo "4) 🔙 Вернуться в главное меню"
        echo "========================================="
        read -p "Выберите действие (1-4): " subchoice

        case $subchoice in
          1)
            echo "▶️ Включаем мониторинг пропозалов..."
            # Запуск мониторинга
            ;;
          2)
            echo "📊 Проверяем статус мониторинга пропозалов..."
            # Проверка процесса или логов
            ;;
          3)
            echo "⛔ Останавливаем мониторинг пропозалов..."
            # Остановка мониторинга
            ;;
          4)
            echo "🔙 Возвращаемся в главное меню..."
            break
            ;;
          *)
            echo "🚫 Неверный выбор, пожалуйста, выберите от 1 до 4."
            ;;
        esac
      done
      ;;
    8)
      echo "❌ Выход из программы..."
      break
      ;;
    *)
      echo "🚫 Неверный выбор, пожалуйста, выберите пункт от 1 до 8."
      ;;
  esac
done
