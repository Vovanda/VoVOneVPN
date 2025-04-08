#!/bin/bash
source "/vovOneVPN/scripts/log.sh"

if [ -z "$DUCKDNS_TOKEN" ] || [ -z "$CERTBOT_VALIDATION" ]; then
    log "Ошибка: Не найдены обязательные переменные." "Error"
    exit 1
fi

# Извлекаем основной домен (до первого .)
BASE_DOMAIN=$(echo "$CERTBOT_DOMAIN" | awk -F. '{print $(NF-2)"."$(NF-1)"."$NF}')

log "Установка TXT записи для $BASE_DOMAIN с валидацией: $CERTBOT_VALIDATION"

response=$(curl -s "https://www.duckdns.org/update?domains=$BASE_DOMAIN&token=$DUCKDNS_TOKEN&txt=$CERTBOT_VALIDATION")

if [[ "$response" == *"OK"* ]]; then
    log "DNS обновление прошло успешно." "Success"
else
    log "Ошибка DNS обновления: $response" "Error"
    exit 1
fi

COUNTDOWN=120
log "Ожидание появления TXT-записи _acme-challenge.$CERTBOT_DOMAIN в DNS (максимум $COUNTDOWN секунд)..."

FOUND=0
for ((i=0; i<COUNTDOWN; i++)); do
    if [[ $FOUND -eq 0 ]]; then
        # Используем dig для проверки TXT записи
        TXT_RESULT=$(dig +short TXT _acme-challenge."$CERTBOT_DOMAIN" @8.8.8.8)  # Пример с Google DNS
        DIG_EXIT_CODE=$?  # Код выхода команды dig

        if [[ $DIG_EXIT_CODE -ne 0 ]]; then
            log "Ошибка при запросе DNS через dig. Код ошибки: $DIG_EXIT_CODE" "Error"
            exit 1
        fi

        # Проверяем, нашли ли мы нужную запись
        if [[ "$TXT_RESULT" == *"$CERTBOT_VALIDATION"* ]]; then
            FOUND=1
            echo -ne "\rOK\n"
            log "TXT-запись найдена после ${i}s." "Success"
        fi
    fi

    # Печать оставшихся секунд
    echo -ne "\r$((COUNTDOWN - i)) "
    sleep 1
done

# Логирование результатов
if [[ $FOUND -eq 0 ]]; then
    echo -e "\n⚠ Не удалось обнаружить TXT-запись в течение $COUNTDOWN секунд. Продолжаем принудительно."
    log "Предупреждение: TXT-запись не обнаружена после $COUNTDOWN секунд. Возможно, DNS ещё не обновился." "Warning"
else
    log "TXT-запись подтверждена через DNS." "Success"
fi
