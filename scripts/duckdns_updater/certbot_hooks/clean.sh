#!/bin/bash
source "/vovOneVPN/scripts/log.sh"

# Извлекаем основной домен (до первого .)
BASE_DOMAIN=$(echo "$CERTBOT_DOMAIN" | awk -F. '{print $(NF-2)"."$(NF-1)"."$NF}')

log "Очистка TXT записи для $BASE_DOMAIN.duckdns.org"

response=$(curl -s "https://www.duckdns.org/update?domains=$BASE_DOMAIN&token=$DUCKDNS_TOKEN&txt=&clear=true")

if [[ "$response" == *"OK"* ]]; then
    log "TXT запись очищена успешно." "Success"
else
    log "Ошибка при очистке TXT записи: $response" "Error"
fi
