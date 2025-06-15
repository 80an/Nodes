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
