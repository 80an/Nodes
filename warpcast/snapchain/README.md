✅ 1. Убедитесь, что Docker установлен
Проверьте наличие Docker:
```
docker --version
```

✅ 2. Запустите Docker-демон
На системах с systemd (Ubuntu, Debian и т.д.):

```
sudo systemctl start docker
```
Если хотите, чтобы Docker запускался автоматически при загрузке:

bash
Копировать
Редактировать
```
sudo systemctl enable docker
```
✅ 3. Повторите обновление Snapchain
```
cd ~/snapchain
docker compose pull
docker compose up -d --force-recreate
```
✅ (Опционально) Проверка статуса Docker
Убедитесь, что Docker работает:

```
sudo systemctl status docker
```

💡 Проверка, что всё работает:
```
docker compose ps
```
Покажет статус всех контейнеров (они должны быть в состоянии Up).

Скрин
```
sudo apt install screen -y && screen -Rd snapchain
```


✅ Что ты сделал:
🛠️ 1. Подготовка среды:
Скрипт для установки зависимостей:

Rust, Cargo, CMake, Protobuf, Docker, grpcurl и др.

Проверка всех ключевых бинарей

Грамотная диагностика и сообщение о next steps

Поддержка как root, так и обычного пользователя (через newgrp docker)

📌 Ты создал полноценный bootstrap-скрипт для серверной подготовки, который можно переиспользовать на любом сервере.

🧱 2. Сборка snapchain из исходников:
Репозитории:

eth-signature-verifier (фиксированный коммит)

malachite (фиксированный коммит)

snapchain (по ветке main)

Умная логика обновления или клонирования

cargo build после подготовки

📌 Теперь у тебя есть локальный бинарь ./snapchain, который ты можешь запускать напрямую (например, ./snapchain --version)

🐳 3. Работа с Docker-нодой:
Выполнил docker compose pull и docker compose up -d --force-recreate

Обновил ноду по инструкции из README

📌 Это гарантирует, что твоя нода работает на последнем образе Docker, синхронизируется с сетью и продолжает работу корректно.

🔍 Что ещё можно сделать (по желанию):
🧪 Проверка статуса ноды
bash
Копировать
Редактировать
curl http://localhost:3381/v1/info | jq
🔁 grpcurl для тестов RPC
bash
Копировать
Редактировать
docker compose exec node1 grpcurl -plaintext localhost:50051 list
или из хоста (если порты проброшены):

bash
Копировать
Редактировать
grpcurl -plaintext localhost:50051 list
🔧 Проверка локальной версии собранного бинаря
bash
Копировать
Редактировать
cd ~/snapchain/snapchain
./target/debug/snapchain --version


Чтобы обновиться до последней версии Snapchain (например, v0.3.0), тебе нужно:

✅ Шаг 1: Убедиться, что нужная версия существует
Проверь доступные теги:

bash
Копировать
Редактировать
cd ~/snapchain
git fetch --tags
git tag -l
Если v0.3.0 есть в списке — отлично. Тогда:

🔄 Шаг 2: Переключиться на нужный тег
bash
Копировать
Редактировать
git checkout v0.3.0
Если покажет ошибку pathspec 'v0.3.0' did not match..., значит тег называется иначе (например, 0.3.0 без v), уточни:

bash
Копировать
Редактировать
git tag -l | grep 0.3
🔨 Шаг 3: Пересобрать проект
bash
Копировать
Редактировать
cargo clean
cargo build
💡 Также можно собрать релизную версию:

bash
Копировать
Редактировать
cargo build --release
Тогда бинарник будет тут:

arduino
Копировать
Редактировать
target/release/snapchain
