#!/bin/bash

# Уровни логирования (по возрастанию приоритета)
declare -A LOG_LEVELS=(
    [DEBUG]=0
    [INFO]=1
    [WARNING]=2
    [ERROR]=3
    [SUCCESS]=4
    [UNKNOWN]=5  # Всегда выводится
)

# Уровень логирования по умолчанию
LOG_LEVEL="${LOG_LEVEL:-INFO}"

# Функция логирования
log() {
    local message="$1"
    local log_type="${2^^}"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    # Определение типа сообщения
    [[ -z "$log_type" ]] && log_type="INFO"
    [[ ! -v LOG_LEVELS[$log_type] ]] && log_type="UNKNOWN"

    # Цвета для терминала
    declare -A colors=(
        [DEBUG]="\033[0;90m"       # Серый
        [INFO]="\033[0;36m"        # Голубой
        [WARNING]="\033[0;33m"     # Желтый
        [ERROR]="\033[0;31m"       # Красный
        [SUCCESS]="\033[0;32m"     # Зеленый
        [UNKNOWN]="\033[1;35m"     # Яркий пурпурный (маджента)
    )

    # Проверка уровня логирования
    if (( ${LOG_LEVELS[$log_type]} >= ${LOG_LEVELS[${LOG_LEVEL^^}]} )) || [[ "$log_type" == "UNKNOWN" ]]; then
        echo -e "${colors[$log_type]}${message}\033[0m"
    fi

    # Запись в файл (все сообщения)
    if [[ -n "$LOG_FILE" ]]; then
        init_log_file
        echo "[${timestamp}] [${log_type}] ${message}" >> "$LOG_FILE"
    fi
}

# Инициализация лог-файла
init_log_file() {
    if [[ ! -d "$(dirname "$LOG_FILE")" ]]; then
        mkdir -p "$(dirname "$LOG_FILE")" || return 1
    fi
    touch "$LOG_FILE" && chmod 600 "$LOG_FILE"
}


# Экспортируем функции
export -f log