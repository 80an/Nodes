# 🛰 Monitoring

Эта директория содержит скрипты для мониторинга валидатора и пропозалов в сети **0Gchaind**. Скрипты интегрированы с Telegram для получения уведомлений в реальном времени.

## 📂 Содержимое

- `monitor_validator.sh` — отслеживает состояние валидатора (активен, jailed, пропускает блоки).
- `monitor_proposal.sh` — следит за появлением новых пропозалов и уведомляет при их обнаружении.

## 📦 Зависимости

- `jq` — для работы с JSON-ответами
- `curl` — для отправки уведомлений в Telegram
- `0gchaind` — бинарник клиента сети
- Файл переменных окружения: `~/.validator_config/env`, содержащий:

  ```bash
  TELEGRAM_BOT_TOKEN='your_bot_token'
  TELEGRAM_CHAT_ID='your_chat_id'
  VALIDATOR_ADDRESS='your_validator_address'

## 🚀 Запуск

Для запуска скриптов:

```bash
nohup bash ~/.validator_config/monitoring_validator.sh > /dev/null 2>&1 &
```

```bash
nohup bash ~/.validator_config/monitoring_proposals.sh > /dev/null 2>&1 &
```

Также можно запускать и останавливать мониторинг через основное меню `menu_validator.sh` в разделе "📡 Мониторинг".

  ## 📬 Telegram уведомления

Скрипты отправляют уведомления в чат Telegram через вашего бота. Настройка осуществляется автоматически при первом запуске меню, либо вручную путём добавления переменных в `~/.validator_config/env`.

  ## 🧹 Остановка

Для остановки скриптов:

```bash
kill $(cat ~/.validator_config/monitor_validator.pid)
```

```bash
kill $(cat ~/.validator_config/monitor_proposals.pid)
```

Или через меню: "📡 Мониторинг → ⏹ Отключить мониторинг ..."

  ##

🎯 Скрипты предназначены для непрерывной работы в фоне и могут быть добавлены в автозагрузку сервера при необходимости.
