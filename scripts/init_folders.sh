#!/bin/bash

# Импортируем функцию логирования
source ./scripts/log.sh

# Создание папок и установка прав
init_folders() {
  log "Создаем необходимые директории и устанавливаем права..."

  # Ассоциативный массив: [папка]="права"
  declare -A dirs_to_create=( 
    ["./nginx/auth"]="750"
    ["./certs"]="755"
    ["./nginx/data"]="755"
    ["./x-ui/data"]="755"
    ["./3x-ui/data/db"]="755"          # Для SQLite БД (требует записи)
    ["./3x-ui/data/config"]="755"      # Для конфигурации
    ["./pritunl/data"]="755"           # Для MongoDB
  )

  # Создаем папки и устанавливаем права
  for dir in "${!dirs_to_create[@]}"; do
    # Создание папки
    if [ ! -d "$dir" ]; then
      mkdir -p "$dir" || { 
        log "Не удалось создать папку: $dir." "ERROR"
        return 1
      }
      log "Папка $dir успешно создана."
    else
      log "Папка $dir уже существует."
    fi

    # Установка прав
    if chmod ${dirs_to_create[$dir]} "$dir"; then
      log "Права ${dirs_to_create[$dir]} для $dir установлены."
    else
      log "Ошибка установки прав для $dir" "WARNING"
      return 1
    fi
  done

  # Особые права для файлов (если файлы уже существуют)
  if [ -f "./3x-ui/data/config/config.json" ]; then
    if chmod 644 ./3x-ui/data/config/config.json; then
      log "Права для конфига установлены."
    else
      log "Ошибка установки прав для конфига." "WARNING"
      return 1
    fi
  fi

  if [ -f "./3x-ui/data/db/x-ui.db" ]; then
    if chmod 666 ./3x-ui/data/db/x-ui.db; then
      log "Права для БД установлены."
    else
      log "Ошибка установки прав для БД." "WARNING"
      return 1
    fi
  fi

  log "Инициализация файловой структуры завершена." "SUCCESS"
}

# Запуск функции
init_folders
