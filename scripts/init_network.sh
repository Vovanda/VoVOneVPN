#!/bin/bash

# Импортируем функцию логирования
source ./scripts/log.sh

# Инициализация Docker-сети
DOCKER_NETWORK="vpn_net"

init_network() {
  log "Инициализация сети $DOCKER_NETWORK началась."

  if ! docker network inspect "$DOCKER_NETWORK" >/dev/null 2>&1; then
    log "Сеть $DOCKER_NETWORK не найдена. Создаем сеть..." "Warning"
    docker network create "$DOCKER_NETWORK"
    log "Сеть $DOCKER_NETWORK создана."
  else
    log "Сеть $DOCKER_NETWORK уже существует."
  fi

  log "Инициализация сети завершена." "Success"
}

# Запуск функции
init_network
