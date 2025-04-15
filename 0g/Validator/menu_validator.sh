#!/bin/bash

# Загружаем переменные окружения из файла
if [ -f "$HOME/.validator_config/env" ]; then
  set -o allexport
  source "$HOME/.validator_config/env"
  set +o allexport
else
  echo "❌ Файл с переменными не найден. Пожалуйста, сначала запустите setup_per.sh."
  exit 1
fi

# Проверка, что все необходимые переменные загружены
if [ -z "$KEYRING_PASSWORD" ] || [ -z "$WALLET_NAME" ] || [ -z "$VALIDATOR_ADDRESS" ]; then
  echo "❌ Необходимые переменные не загружены. Пожалуйста, сначала запустите setup_per.sh."
  exit 1
fi

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
      echo "$KEYRING_PASSWORD" | 0gchaind tx distribution withdraw-rewards "$VALIDATOR_ADDRESS" \
        --chain-id="zgtendermint_16600-2" \
        --from "$WALLET_NAME" \
        --commission \
        --gas=auto \
        --gas-prices=0.003ua0gi \
        --gas-adjustment=1.8 \
        -y
      ;;
    2)
      echo "💸 Забрать все реварды со всех кошельков"
      source <(wget -qO- 'https://raw.githubusercontent.com/80an/Nodes/refs/heads/Punkty-menu/0g/Validator/all_reward.sh')
      ;;
    3)
      echo "📥 Делегировать со всех кошельков в своего валидатора"
      source <(wget -qO- 'https://raw.githubusercontent.com/80an/Nodes/refs/heads/Punkty-menu/0g/Validator/all_delegation.sh')
      ;;
    4)
      echo "🗳 Голосование по пропозалу"
      read -p "Введите номер пропозала: " proposal
      read -p "Введите ваш голос (yes/no/abstain/no_with_veto): " vote
      echo "$KEYRING_PASSWORD" | 0gchaind tx gov vote "$proposal" "$vote" \
        --from "$WALLET_NAME" \
        --chain-id="zgtendermint_16600-2" \
        --gas=auto \
        --gas-prices=0.003ua0gi \
        --gas-adjustment=1.8 \
        -y
      ;;
    5)
      echo "🚪 Вызволить из тюрьмы"
      echo "$KEYRING_PASSWORD" | 0gchaind tx slashing unjail \
        --from "$WALLET_NAME" \
        --chain-id="zgtendermint_16600-2" \
        --gas=auto \
        --gas-prices=0.003ua0gi \
        --gas-adjustment=1.8 \
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
            # TODO: Добавить реализацию
            ;;
          2)
            echo "📊 Проверяем статус мониторинга валидатора..."
            # TODO: Добавить реализацию
            ;;
          3)
            echo "⛔ Останавливаем мониторинг валидатора..."
            # TODO: Добавить реализацию
            ;;
          4)
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
            # TODO: Добавить реализацию
            ;;
          2)
            echo "📊 Проверяем статус мониторинга пропозалов..."
            # TODO: Добавить реализацию
            ;;
          3)
            echo "⛔ Останавливаем мониторинг пропозалов..."
            # TODO: Добавить реализацию
            ;;
          4)
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
