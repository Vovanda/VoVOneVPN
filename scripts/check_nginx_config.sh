#!/bin/bash

# Импортируем функцию логирования
source ./scripts/log.sh

# Проверка конфигов Nginx
check_nginx_config() {
  if [ ! -f nginx/nginx.conf ]; then
    log "Ошибка: Файл nginx/nginx.conf не найден!" "Error"
    log "Проверьте, что конфигурация Nginx настроена корректно." "Warning"
    exit 1
  fi

  if [ ! -f nginx/vpn_stealth.conf ]; then
    log "Ошибка: Файл nginx/vpn_stealth.conf не найден!" "Error"
    log "Этот конфиг необходим для стелс-режима VPN." "Warning"
    exit 1
  fi
}

# Запуск функции
check_nginx_config