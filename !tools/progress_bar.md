Прогресс бар

🔧 Функция прогресс-бара в Bash

```
progress_bar() {
  local progress=$1
  local width=50
  local done=$((progress * width / 100))
  local left=$((width - done))
  local fill=$(printf "%${done}s")
  local empty=$(printf "%${left}s")
  printf "\rProgress: [\e[32m%s\e[0m%s] %d%%" "${fill// /#}" "${empty// /.}" "$progress"
}
```
📦 Пример использования при установке

```
echo "Starting installation..."
for i in {1..100}; do
  progress_bar "$i"
  sleep 0.05  # Имитация какой-то работы
done
echo -e "\nInstallation completed."
```
💡 Использование с реальными командами
Можно вызывать прогресс-бар после каждого шага установки:


```
sudo apt update -y && progress_bar 10
sudo apt install curl -y && progress_bar 30
sudo apt install docker.io -y && progress_bar 50
# и так далее...
```
