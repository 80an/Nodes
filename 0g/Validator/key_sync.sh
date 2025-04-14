sync_keys_from_os_to_file() {
  echo "🔑 Синхронизация ключей из keyring-backend=os в keyring-backend=file..."

   # ✅ Исправлено: используем полный флаг --output
  local os_keys
  os_keys=$(printf "%s\n" "$KEYRING_PASSWORD" | 0gchaind keys list --keyring-backend os --output json | jq -r '.[].name')


  for key in $os_keys; do
    # Проверяем, есть ли ключ уже в file-хранилище
    local exists
    exists=$(0gchaind keys show "$key" --keyring-backend file -o json 2>/dev/null)

    if [[ -z "$exists" ]]; then
      echo "➕ Импортируем $key в file-хранилище"
      printf "%s\n" "$KEYRING_PASSWORD" | 0gchaind keys export "$key" --keyring-backend os | \
      0gchaind keys import "$key" --keyring-backend file
    else
      echo "✅ Ключ $key уже есть в file-хранилище"
    fi
  done

  echo "🎉 Синхронизация завершена."
}
