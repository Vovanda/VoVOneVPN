#!/bin/bash

# === НАСТРОЙКИ ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
CONFIG_FILE="$SCRIPT_DIR/duckdns_updater.conf"
SECRETS_FILE="$SCRIPT_DIR/duckdns_updater.secrets.conf"
DEFAULT_LOG_FILE="$SCRIPT_DIR/duckdns_updater.log"
SCRIPT_NAME="$(basename "$0")"

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

# Добавление задачи в cron для обновления сертификатов
add_cron_job() {
    # Рассчитываем интервал обновлений в минутах для cron
    update_interval_minutes=$((DAYS_BETWEEN_UPDATES * 24 * 60))

    # Проверяем, существует ли уже задача cron
    existing_cron=$(crontab -l | grep -F "$SCRIPT_NAME")

    if [ -z "$existing_cron" ]; then
        # Если задачи нет, добавляем новую задачу в cron
        log "Добавление задачи в cron для обновления сертификатов." "Info"
        (crontab -l; echo "0 3 */$DAYS_BETWEEN_UPDATES * * $SCRIPT_DIR/$SCRIPT_NAME update_certificates >> $DEFAULT_LOG_FILE 2>&1") | crontab -
        log "Задача cron добавлена успешно." "Success"
    else
        log "Задача cron уже существует." "Info"
    fi
}

# Функция для вывода информации о путях к сертификатам
info() {
    echo -e "Доступные команды: \033[1;32mupdate_duckdns\033[0m, \033[1;32mupdate_certificates\033[0m, \033[1;32mfull_update\033[0m, \033[1;34minfo\033[0m"
    
    echo "Конфигурационные файлы:"
    echo "Конфигурационный файл: $CONFIG_FILE"
    echo "Файл с секретами: $SECRETS_FILE"
    echo "Лог файл: $LOG_FILE"

    echo "Текущие настройки:"
    echo "Поддомены DuckDNS: $DUCKDNS_SUBDOMAINS"
    echo "Интервал обновления (в днях): $DAYS_BETWEEN_UPDATES"
    echo "Автообновление: $AUTO_UPDATE"

    echo "Пути к файлам:"
    echo "Путь к скрипту: $SCRIPT_DIR"
    echo "Путь к файлу с логами: $DEFAULT_LOG_FILE"

    echo "Пути к сертификатам:"
    # Путь к сертификатам, если они существуют
    for sub in "${SUBDOMAINS[@]}"; do
        cert_path="/etc/letsencrypt/live/${sub}.duckdns.org/fullchain.pem"
        privkey_path="/etc/letsencrypt/live/${sub}.duckdns.org/privkey.pem"
        
        if [ -f "$cert_path" ] && [ -f "$privkey_path" ]; then
            echo "Сертификат для поддомена ${sub}.duckdns.org:"
            echo "  Путь к сертификату: $cert_path"
            echo "  Путь к приватному ключу: $privkey_path"
        else
            echo "Сертификат для поддомена ${sub}.duckdns.org не найден."
        fi
    done

    log "Задачи в cron:" "Info"
    # Печатаем задачи cron для текущего пользователя
    crontab -l | grep "$SCRIPT_NAME"
}

# Функция для обновления записи DNS на DuckDNS
update_duckdns() {
    log "Начало обновления DNS для поддоменов DuckDNS."

    # Для каждого поддомена обновляем DNS запись
    for sub in "${SUBDOMAINS[@]}"; do
        log "Обновление DNS записи для поддомена: ${sub}.duckdns.org"

        # Выполняем запрос к API DuckDNS для обновления DNS записи
        response=$(curl -s "https://www.duckdns.org/update?domains=${sub}&token=${DUCKDNS_TOKEN}&ip=")

        # Проверка успешности обновления
        if [[ "$response" == "OK" ]]; then
            log "DNS запись для поддомена ${sub}.duckdns.org обновлена успешно." "Success"
        else
            log "Ошибка при обновлении DNS записи для поддомена ${sub}.duckdns.org." "Error"
        fi

        # Добавляем задержку, чтобы избежать частых запросов
        log "Ожидание перед обработкой следующего поддомена..."
        sleep 10
    done

    log "Обновление DNS завершено."
}

# Основной блок обработки команд
case "$1" in
    update_duckdns) update_duckdns ;;
    update_certificates) update_certificates ;;
    full_update) update_duckdns && sleep 5 && update_certificates && add_cron_job;;
    info) info ;;
    add_cron) add_cron_job ;;  # Добавлен новый режим
    *)
        info
        ;;
esac

LOG_FILE="$PREV_LOG_FILE"