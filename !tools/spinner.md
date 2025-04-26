Такой спиннер — ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏ — легко реализовать в bash с помощью анимации в цикле. Вот простой пример:

🌀 Спиннер (анимация загрузки) в Bash

```
spinner() {
  local pid=$!
  local delay=0.1
  local spinstr='⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    for (( i=0; i<${#spinstr}; i++ )); do
      printf "\r[%s] Processing..." "${spinstr:$i:1}"
      sleep "$delay"
    done
  done
  printf "\r[✔] Done.         \n"
}
```

📦 Использование со скриптом

```
(sleep 5) &  # Имитация долгой команды
spinner
```

Или с реальной командой:

```
(sudo apt update -y) & spinner
```
