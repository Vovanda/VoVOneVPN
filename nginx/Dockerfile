FROM nginx:stable

# Установка необходимых утилит
RUN apt-get update && apt-get install -y procps && rm -rf /var/lib/apt/lists/*

# Копируем конфиги и скрипты
COPY ./nginx.template.conf /etc/nginx/nginx.template.conf
COPY ./vpn_stealth.template.conf /etc/nginx/vpn_stealth.template.conf
COPY ./entrypoint.sh /entrypoint.sh
COPY ./.env /.env

# Устанавливаем базовые лимиты
RUN echo "fs.file-max=2097152" >> /etc/sysctl.conf && \
    echo "nginx soft nofile 65535" >> /etc/security/limits.conf && \
    echo "nginx hard nofile 65535" >> /etc/security/limits.conf

RUN chmod +x /entrypoint.sh

# Отключаем IPv6
RUN mv /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh.disabled

ENTRYPOINT ["/entrypoint.sh"]

# CMD не указывается, так как entrypoint.sh сам вызовет команду "nginx -g 'daemon off;'"