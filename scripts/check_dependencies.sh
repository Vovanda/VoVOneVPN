#!/bin/bash

# Импортируем функцию логирования
source ./scripts/log.sh

# Проверка зависимостей
check_dependencies() {
  log "Проверка зависимостей началась." "INFO"

  # Установка jq
  if ! command -v jq >/dev/null 2>&1; then
    log "Утилита jq не найдена. Устанавливаем..." "WARNING"
    sudo apt update && sudo apt install -y jq
    if ! command -v jq >/dev/null 2>&1; then
      log "Не удалось установить jq! Требуется ручная установка." "ERROR"
      exit 1
    fi
    log "jq успешно установлен." "SUCCESS"
  fi

  # Проверка Docker
  if ! command -v docker >/dev/null 2>&1; then
    log "Docker не установлен. Устанавливаем..." "WARNING"
    sudo apt update && sudo apt install -y docker.io
  else
    log "Docker уже установлен. Обновляем..." "INFO"
    sudo apt update && sudo apt upgrade -y docker.io
  fi

  # Проверка Docker Compose
  if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
    log "Docker Compose не найден. Устанавливаем..." "WARNING"
    sudo apt update && sudo apt install -y docker-compose-plugin
  fi

  # Проверка остальных зависимостей
  declare -a required_tools=("htpasswd" "curl" "openssl")
  for tool in "${required_tools[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      log "$tool не найден. Устанавливаем..." "WARNING"
      sudo apt update && sudo apt install -y "$tool"
    fi
  done

  # Финал проверки
  log "\nРезультаты проверки:" "HEADER"
  log "• Docker: $(docker --version 2>/dev/null || echo 'недоступен')" "INFO"
  log "• Docker Compose: $(docker compose version 2>/dev/null || docker-compose --version 2>/dev/null || echo 'недоступен')" "INFO"
  log "• jq: $(jq --version 2>/dev/null || echo 'недоступен')" "INFO"
  log "• htpasswd: $(htpasswd -v 2>&1 | head -n1 || echo 'недоступен')" "INFO"
  
  log "Проверка зависимостей завершена." "SUCCESS"
}

# Запуск функции
check_dependencies

# Проверка кода возврата
if [ $? -ne 0 ]; then
  log "Критические ошибки в зависимостях!" "ERROR"
  exit 1
fi