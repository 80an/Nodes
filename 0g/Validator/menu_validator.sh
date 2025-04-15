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
  echo "6) 📡 Мониторинг"
  echo "7) ❌ Выход"
  echo "=================================================="
  echo

  read -p "Выберите пункт меню (1-7): " choice

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
      if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
        echo "🤖 Введите параметры Telegram-бота для мониторинга:"
        read -p "🔑 Telegram Bot Token: " TELEGRAM_BOT_TOKEN
        read -p "💬 Telegram Chat ID: " TELEGRAM_CHAT_ID
        mkdir -p "$HOME/.validator_config"
        echo "TELEGRAM_BOT_TOKEN=\"$TELEGRAM_BOT_TOKEN\"" >> "$HOME/.validator_config/env"
        echo "TELEGRAM_CHAT_ID=\"$TELEGRAM_CHAT_ID\"" >> "$HOME/.validator_config/env"
        export TELEGRAM_BOT_TOKEN TELEGRAM_CHAT_ID
      fi

      while true; do
        echo
        echo "========= 📡 Подменю мониторинга ========="
        echo "1) ▶️ Включить мониторинг валидатора"
        echo "2) ▶️ Включить мониторинг пропозалов"
        echo "3) 📊 Состояние мониторинга"
        echo "4) ⏹ Отключить мониторинг валидатора"
        echo "5) ⏹ Отключить мониторинг пропозалов"
        echo "6) 🔙 Вернуться в главное меню"
        echo "=========================================="

        read -p "Выберите действие (1-6): " subchoice

        case $subchoice in
          1)
            echo "▶️ Включаем мониторинг валидатора..."
            # TODO: Добавить реализацию
            ;;
          2)
            echo "▶️ Включаем мониторинг пропозалов..."
            # TODO: Добавить реализацию
            ;;
          3)
            echo "📊 Проверяем статус мониторинга..."
            # TODO: Добавить реализацию
            ;;
          4)
            echo "⛔ Останавливаем мониторинг валидатора..."
            # TODO: Добавить реализацию
            ;;
          5)
            echo "⛔ Останавливаем мониторинг пропозалов..."
            # TODO: Добавить реализацию
            ;;
          6)
            break
            ;;
          *)
            echo "🚫 Неверный выбор, пожалуйста, выберите от 1 до 6."
            ;;
        esac
      done
      ;;
    7)
      echo "❌ Выход из программы..."
      break
      ;;
    *)
      echo "🚫 Неверный выбор, пожалуйста, выберите пункт от 1 до 7."
      ;;
  esac

done
