Ошибка Cannot connect to the Docker daemon at unix:///var/run/docker.sock означает, что Docker-демон не запущен. Чтобы это исправить, выполните следующие шаги:

✅ 1. Убедитесь, что Docker установлен
Проверьте наличие Docker:

bash
Копировать
Редактировать
docker --version
Если команда не найдена, установите Docker:

bash
Копировать
Редактировать
curl -fsSL https://get.docker.com | bash
✅ 2. Запустите Docker-демон
На системах с systemd (Ubuntu, Debian и т.д.):

bash
Копировать
Редактировать
sudo systemctl start docker
Если хотите, чтобы Docker запускался автоматически при загрузке:

bash
Копировать
Редактировать
sudo systemctl enable docker
✅ 3. Повторите обновление Snapchain
bash
Копировать
Редактировать
cd ~/snapchain
docker compose pull
docker compose up -d --force-recreate
✅ (Опционально) Проверка статуса Docker
Убедитесь, что Docker работает:

bash
Копировать
Редактировать
sudo systemctl status docker


💡 Проверка, что всё работает:
bash
Копировать
Редактировать
docker compose ps
Покажет статус всех контейнеров (они должны быть в состоянии Up).
