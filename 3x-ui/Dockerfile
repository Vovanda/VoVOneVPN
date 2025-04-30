FROM ghcr.io/mhsanaei/3x-ui:latest

RUN apk add --no-cache --update \
	ca-certificates \
	tzdata \
    bash \
    curl \
    jq \
    fail2ban \
    sudo \
    gnupg \
    openssl

WORKDIR /app

# Копируем кастомный конфиг fail2ban (если нужен)
COPY ./data/config/fail2ban.local /etc/fail2ban/fail2ban.local

# Вспомогательный скрипт — чисто для ручного запуска
COPY x-ui-docker.sh /app/x-ui-docker.sh
RUN chmod +x /app/x-ui-docker.sh

VOLUME [ "/etc/x-ui", "/root/cert" ]
CMD [ "./x-ui" ]

# Используем кастомный entrypoint
ENTRYPOINT ["/app/DockerEntrypoint.sh"]