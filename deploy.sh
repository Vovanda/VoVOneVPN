#!/bin/bash
# ==============================================
# Главный скрипт деплоя vovOneVPN
# ==============================================

# Цвета для вывода
COLOR_DEBUG='\033[0;37m'    # Серый
COLOR_INFO='\033[0;36m'     # Голубой
COLOR_WARNING='\033[0;33m'  # Желтый
COLOR_ERROR='\033[0;31m'    # Красный
COLOR_SUCCESS='\033[0;32m'  # Зеленый
COLOR_RESET='\033[0m'       # Сброс цвета

# Глобальные настройки
PROJECT_ROOT="/vovOneVPN"
PROJECT_NAME="vovonevpn"
COMPOSE_FILE="${PROJECT_ROOT}/docker-compose.yml"
LOG_FILE="${PROJECT_ROOT}/deploy.log"
SCRIPTS_DIR="${PROJECT_ROOT}/scripts"
export PROJECT_ROOT PROJECT_NAME COMPOSE_FILE LOG_FILE 

# Импорт функций логирования
source "${SCRIPTS_DIR}/log.sh"

# Массив шагов деплоя
DEPLOY_STEPS=(
    "init_folders.sh" 
    "generate_passwords.sh"
    "check_dependencies.sh"
    "update_dns_and_certs.sh"
    "start_services.sh"
)

# Главная функция
main() {
    log "Начало деплоя проекта ${PROJECT_NAME}" "INFO"
    
    # Проверка корневой директории
    if [ ! -d "${PROJECT_ROOT}" ]; then
        log "Корневая директория проекта не найдена!" "ERROR"
        exit 1
    fi
    
    # Последовательное выполнение шагов
    for step in "${DEPLOY_STEPS[@]}"; do
        log "Запуск шага: ${step}" "INFO"
        
        if [ ! -x "${SCRIPTS_DIR}/${step}" ]; then
            log "Скрипт ${step} не найден или недоступен!" "ERROR"
            exit 1
        fi
        
        if ! "${SCRIPTS_DIR}/${step}"; then
            log "Деплой прерван на шаге: ${step}" "ERROR"
            exit 1
        fi
        
        log "Шаг успешно выполнен: ${step}" "SUCCESS"
    done
    
    log "Деплой успешно завершен!" "SUCCESS"
    
    # Финализация
    echo -e "\n${COLOR_INFO}Итоговый статус сервисов:${COLOR_RESET}"
    docker-compose -p "${PROJECT_NAME}" ps
}

# Запуск
main