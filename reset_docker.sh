#!/bin/bash
# ==============================================
# Safe Reset Docker State with Docker Compose
# ==============================================
set -euo pipefail

# Импорт модуля логирования
source ./scripts/log.sh

# Конфигурация
PROJECT_NAME="vovonevpn"
LOG_FILE="${LOG_FILE:-./reset_docker.log}"
declare -A COLOR=(
    [header]='\033[1;36m'
    [success]='\033[0;32m' 
    [warning]='\033[0;33m'
    [error]='\033[0;31m'
    [option]='\033[0;94m'
    [reset]='\033[0m'
)

# Проверка версии Docker
check_docker_version() {
    local version
    version=$(docker version --format '{{.Client.Version}}' 2>/dev/null)
    if [[ "$version" < "20.10.0" ]]; then
        log "Требуется Docker версии 20.10.0 или выше. Текущая версия: $version" "ERROR"
        exit 1
    fi
}

# Проверка зависимостей
check_dependencies() {
    check_docker_version
    
    # Проверка наличия docker compose (v2)
    if ! docker compose version &>/dev/null; then
        log "Ошибка: Docker Compose плагин не установлен" "ERROR"
        exit 1
    fi
}

# Получение ресурсов проекта
get_project_resources() {
    # Контейнеры
    mapfile -t containers < <(
        docker ps -aq --filter "label=com.docker.compose.project=$PROJECT_NAME"
    )
    
    # Образы
    mapfile -t images < <(
        docker images -q --filter "label=com.docker.compose.project=$PROJECT_NAME"
    )
    
    # Тома
    mapfile -t volumes < <(
        docker volume ls -q --filter "label=com.docker.compose.project=$PROJECT_NAME"
    )
    
    # Сети
    mapfile -t networks < <(
        docker network ls -q --filter "name=${PROJECT_NAME}_"
    )
}

# Вывод информации о проекте (исправленная версия)
print_project_info() {
    echo -e "${COLOR[header]}\n=== Текущее состояние проекта ===${COLOR[reset]}"
    
    # Контейнеры
    if [ ${#containers[@]} -gt 0 ]; then
        echo -e "\n${COLOR[option]}Контейнеры:${COLOR[reset]}"
        docker ps --filter "label=com.docker.compose.project=$PROJECT_NAME" \
            --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
    fi

    # Образы
    if [ ${#images[@]} -gt 0 ]; then
        echo -e "\n${COLOR[option]}Образы:${COLOR[reset]}"
        docker images --filter "label=com.docker.compose.project=$PROJECT_NAME" \
            --format "table {{.ID}}\t{{.Repository}}\t{{.Tag}}\t{{.Size}}"
    fi

    # Тома
    if [ ${#volumes[@]} -gt 0 ]; then
        echo -e "\n${COLOR[option]}Тома:${COLOR[reset]}"
        docker volume ls --filter "label=com.docker.compose.project=$PROJECT_NAME"
    fi

    # Сети
    if [ ${#networks[@]} -gt 0 ]; then
        echo -e "\n${COLOR[option]}Сети:${COLOR[reset]}"
        docker network ls --filter "name=${PROJECT_NAME}_"
    fi
}

# Остальные функции остаются без изменений
# ... (remove_resources, reset_project, show_help, main)

main "$@"