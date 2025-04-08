#!/bin/bash

# === НАСТРОЙКИ ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
CONFIG_FILE="$SCRIPT_DIR/duckdns_updater.conf"
SECRETS_FILE="$SCRIPT_DIR/duckdns_updater.secrets.conf"
DEFAULT_LOG_FILE="$SCRIPT_DIR/duckdns_updater.log"

# Подключение логирования
source "/vovOneVPN/scripts/log.sh"

# Перенаправляем лог
PREV_LOG_FILE="$LOG_FILE"
LOG_FILE="$DEFAULT_LOG_FILE"

# Функция для запроса данных у пользователя и сохранения в файл
request_input() {
    local prompt="$1"
    local var_name="$2"
    local default_value="$3"
    local regex="$4"
    
    read -p "$prompt" user_input
    user_input="${user_input:-$default_value}"

    while [[ ! "$user_input" =~ $regex ]]; do
        echo "Некорректный ввод. Повторите."
        read -p "$prompt" user_input
        user_input="${user_input:-$default_value}"
    done

    eval "$var_name=\"$user_input\""
}

# Функция создания конфигурационного файла
create_config() {
    # Проверка существования и заполненности файлов конфигурации и секретов
    if [ ! -f "$SECRETS_FILE" ] || [ ! -s "$SECRETS_FILE" ]; then
        log "Файл с секретами пуст или отсутствует. Запрашиваем токен." "Info"
        request_input "Введите токен DuckDNS: " "DUCKDNS_TOKEN" "" "^[a-zA-Z0-9]+$"
        echo "DUCKDNS_TOKEN=$DUCKDNS_TOKEN" > "$SECRETS_FILE"
        chmod 600 "$SECRETS_FILE"
        log "Токен сохранён в файл с секретами." "Success"
    fi

    if [ ! -f "$CONFIG_FILE" ] || [ ! -s "$CONFIG_FILE" ]; then
        log "Конфигурация пустая. Запрашиваем данные." "Info"

        # Запрос конфигурации
        request_input "Введите поддомены DuckDNS (через запятую): " "DUCKDNS_SUBDOMAINS" "" "^[a-zA-Z0-9,.*-]+$"
        request_input "Интервал обновления в днях [60]: " "DAYS_BETWEEN_UPDATES" "60" "^[0-9]+$"
        request_input "Включить автообновление (true/false) [false]: " "AUTO_UPDATE" "false" "^(true|false)$"
        
        # Сохраняем конфигурацию в файл
        cat > "$CONFIG_FILE" <<EOL
DUCKDNS_SUBDOMAINS="$DUCKDNS_SUBDOMAINS"
DAYS_BETWEEN_UPDATES=$DAYS_BETWEEN_UPDATES
AUTO_UPDATE=$AUTO_UPDATE
EOL
        chmod 600 "$CONFIG_FILE"
        log "Конфигурационный файл заполнен." "Success"
    fi
}

# Загружаем конфигурацию
source "$CONFIG_FILE"
create_config
source "$SECRETS_FILE"
# Экспортируем токен в переменные окружения
export DUCKDNS_TOKEN

# Разбор поддоменов
IFS=',' read -ra SUBDOMAINS <<< "$(echo "$DUCKDNS_SUBDOMAINS" | tr -d ' ')"

# Обновление сертификатов
update_certificates() {
    log "Обновление сертификатов началось."

    # Для каждого поддомена обновляем сертификаты последовательно
    for sub in "${SUBDOMAINS[@]}"; do
        log "Обновление сертификатов для поддомена: ${sub}.duckdns.org"

        certbot certonly \
            --manual \
            --preferred-challenges=dns \
            --manual-auth-hook "$SCRIPT_DIR/certbot_hooks/auth.sh" \
            --manual-cleanup-hook "$SCRIPT_DIR/certbot_hooks/clean.sh" \
            --non-interactive \
            --agree-tos \
            --email "admin@${sub}.duckdns.org" \
            --cert-name "${sub}.duckdns.org" \
            -d "${sub}.duckdns.org"

        # Проверяем, прошла ли валидация
        if [ $? -eq 0 ]; then
            log "Сертификат для поддомена ${sub}.duckdns.org обновлён." "Success"
        else
            log "Ошибка при обновлении сертификата для поддомена ${sub}.duckdns.org." "Error"
        fi

        # Добавляем задержку, чтобы избежать частых запросов в случае возможной блокировки
        log "Ожидание перед обработкой следующего поддомена..."
        sleep 10  # Можно настроить задержку на своё усмотрение
    done

    log "Обновление сертификатов завершено."
}

# Основной блок обработки команд
case "$1" in
    update_duckdns) update_duckdns ;;
    update_certificates) update_certificates ;;
    full_update) update_duckdns && sleep 5 && update_certificates && reload_nginx ;;
    info) info ;;
    *)
        info
        ;;
esac

LOG_FILE="$PREV_LOG_FILE"
