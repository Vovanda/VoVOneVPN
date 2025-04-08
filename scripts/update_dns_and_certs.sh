#!/bin/bash

# Импортируем функцию логирования
source ./scripts/log.sh

# Функция для копирования сертификатов без символических ссылок и установки нужных прав
copy_and_copy_certs() {
  log "Начало копирования сертификатов без символических ссылок."

  # Пути
  CERT_SRC="/etc/letsencrypt/live"
  CERT_DEST="./certs/live"

  # Создание директорий, если их нет
  mkdir -p "$CERT_DEST"

  # Копирование всех доменов из /etc/letsencrypt/live
  for domain in $(ls -d $CERT_SRC/*/); do
    domain_name=$(basename $domain)

    # Папка назначения для каждого домена
    DOMAIN_DEST="$CERT_DEST/$domain_name"
    
    # Создание директории для домена
    mkdir -p "$DOMAIN_DEST"

    log "Копирование сертификатов для $domain_name..."

    # Копирование всех файлов в папку назначения (без символических ссылок)
    cp "$domain"/* "$DOMAIN_DEST/"

    # Проверка успешности копирования
    if [ $? -eq 0 ]; then
      log "Сертификаты для $domain_name успешно скопированы." "Success"
    else
      log "Ошибка при копировании сертификатов для $domain_name." "Error"
      exit 1
    fi

    # Установка прав доступа для файлов сертификатов
    log "Установка прав доступа для файлов сертификатов для $domain_name..."

    # Устанавливаем права 644 для всех файлов сертификатов
    find "$DOMAIN_DEST" -type f -exec chmod 644 {} \;

    # Устанавливаем права 755 для всех директорий
    find "$DOMAIN_DEST" -type d -exec chmod 755 {} \;

    log "Права доступа для сертификатов $domain_name установлены." "Success"
  done
}

# Запуск функции
copy_and_copy_certs
