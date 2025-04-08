#!/bin/bash

# Импортируем функцию логирования
source ./scripts/log.sh

# Генерация случайных паролей
generate_random_password() {
  tr -dc A-Za-z0-9 </dev/urandom | head -c 12
}

# Генерация паролей и создание файлов .htpasswd
generate_passwords() {
  log "Генерация паролей началась." "Success"

  # Генерация случайных паролей
  scanner_password=$(generate_random_password)
  gateway_password=$(generate_random_password)

  # Создание директории для auth, если её нет
  mkdir -p ./nginx/auth

  # Относительные пути для .htpasswd
  htpasswd -bc ./nginx/auth/scanner.htpasswd vovOne "$scanner_password"
  htpasswd -bc ./nginx/auth/gateway.htpasswd vovOne "$gateway_password"

  log "Пароли сгенерированы: Scanner пароль - $scanner_password, Gateway пароль - $gateway_password" "Success"

  log "Генерация паролей завершена." "Success"
}

generate_passwords
