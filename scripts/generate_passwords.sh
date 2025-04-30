#!/bin/bash

# Импортируем функцию логирования
source ./scripts/log.sh

# Генерация случайных паролей
generate_random_password() {
  tr -dc A-Za-z0-9 </dev/urandom | head -c 12
}

# Проверка наличия утилиты htpasswd
check_htpasswd() {
  if ! command -v htpasswd &> /dev/null; then
    log "Утилита htpasswd не найдена! Установите её и повторите попытку." "ERROR"
    exit 1
  fi
}

# Генерация паролей и создание файлов .htpasswd
generate_passwords() {
  log "Генерация паролей началась." "INFO"
  check_htpasswd || exit 1

  # Создаем директорию
  mkdir -p ./nginx/auth || { 
    log "Не удалось создать директорию ./nginx/auth" "ERROR"
    exit 1
  }

  # Генерация пароля и создание .htpasswd
  scanner_password=$(generate_random_password)
  htpasswd -bc ./nginx/auth/scanner.htpasswd vovOne "$scanner_password" || { 
    log "Ошибка создания .htpasswd" "ERROR"
    exit 1
  } 

  # Устанавливаем владельца файлов через UID/GID (101:101)
  chown -R 101:101 ./nginx/auth || {
    log "Ошибка смены владельца" "ERROR"
    exit 1
  }
  chmod 644 ./nginx/auth/*.htpasswd || {
    log "Ошибка смены прав" "ERROR"
    exit 1
  }

  log "Пароль для scanner domain: $scanner_password" "INFO"
  log "Генерация паролей завершена." "SUCCESS"
}

generate_passwords
