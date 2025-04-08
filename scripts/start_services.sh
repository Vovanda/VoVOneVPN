#!/bin/bash
# ==============================================
# Запуск сервисов проекта vovonevpn
# ==============================================

# Импорт функций логирования
source ./scripts/log.sh

# Настройки проекта (из deploy.sh)

# Определение команды Docker Compose
init_compose_cmd() {
    if command -v docker-compose &> /dev/null; then
        echo "docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME"
    elif command -v docker &> /dev/null; then
        echo "docker compose -f $COMPOSE_FILE -p $PROJECT_NAME"
    else
        log "Ошибка: Docker и Docker Compose не установлены!" "ERROR"
        exit 1
    fi
}

# Запуск сервисов
start_services() {
    local DOCKER_COMPOSE_CMD
    DOCKER_COMPOSE_CMD=$(init_compose_cmd)
    
    log "Инициализация запуска сервисов..." "INFO"

    # Остановка и удаление только текущих сервисов
    log "Остановка существующих сервисов..." "DEBUG"
    if ! $DOCKER_COMPOSE_CMD down; then
        log "Ошибка при остановке сервисов" "ERROR"
        exit 1
    fi

    # Пересборка и запуск
    log "Сборка и запуск контейнеров..." "INFO"
    if ! $DOCKER_COMPOSE_CMD up --build -d; then
        log "Ошибка при запуске сервисов" "ERROR"
        exit 1
    fi

    # Проверка состояния сервисов
    log "Проверка состояния сервисов..." "INFO"
    local attempts=0
    local max_attempts=10

    while [ $attempts -lt $max_attempts ]; do
        ((attempts++))
        local status
        status=$($DOCKER_COMPOSE_CMD ps --services --filter "status=running")
        
        if [ "$(echo "$status" | wc -l)" -eq "$($DOCKER_COMPOSE_CMD ps --services | wc -l)" ]; then
            log "Все сервисы успешно запущены!" "SUCCESS"
            return 0
        fi
        
        sleep 5
    done

    log "Не все сервисы запустились за отведенное время" "WARNING"
    $DOCKER_COMPOSE_CMD ps
    exit 1
}

# Основной вызов
start_services