FROM ghcr.io/mhsanaei/3x-ui:latest

# Установка зависимостей
RUN apk add --no-cache jq

# Настройка Xray
RUN mv /app/bin/xray-linux-amd64 /app/bin/xray && \
    ln -s /app/bin/xray /app/bin/xray-linux-amd64 && \
    chown nobody:nobody /app/bin/xray

# Создание директорий и копирование конфигов
RUN mkdir -p /etc/x-ui/config && \
    chown -R nobody:nobody /etc/x-ui

COPY --chown=nobody:nobody ./data/config/config.json /app/bin/config.json
COPY --chown=nobody:nobody ./data/config/config.json /etc/x-ui/config/config.json
COPY --chown=nobody:nobody ./data/db/x-ui.db /etc/x-ui/x-ui.db

# Применение прав
RUN chmod 664 /app/bin/config.json && \
    chmod 666 /etc/x-ui/x-ui.db && \
    chmod 755 /app/bin/xray && \
    jq empty /app/bin/config.json

# Настройка Fail2ban
RUN mkdir -p /var/run/fail2ban && \
    mkdir -p /var/lib/fail2ban && \
    touch /var/log/fail2ban.log && \
    chown -R nobody:nobody /var/run/fail2ban /var/lib/fail2ban /var/log/fail2ban.log

# Копирование конфига Fail2Ban
COPY --chown=nobody:nobody ./data/config/fail2ban.local /etc/fail2ban/fail2ban.local

# Отладочные команды
RUN echo "=== File list ===" && ls -la /app/bin && \
    echo "=== Xray test ===" && /app/bin/xray --version

USER nobody

# Окружение
ENV XRAY_LOCATION=/app/bin/xray

# Экспонирование портов
EXPOSE 5580

# Запуск X-ui
CMD ["/app/bin/x-ui", "--log=/dev/stdout"]