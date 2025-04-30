#!/bin/sh

# Применяем системные настройки
sysctl -p /etc/sysctl.conf

# Проверяем и увеличиваем лимиты
ulimit -n 65535

# Путь к файлу с переменными окружения
ENV_FILE="${ENV_FILE:-./.env}"

# Проверяем наличие .env файла
if [ ! -f "$ENV_FILE" ]; then
  echo "Ошибка: .env файл не найден по пути $ENV_FILE" >&2
  exit 1
fi

# Извлекаем имена переменных из .env файла (игнорируем комментарии и пустые строки)
VARS_TO_SUBST=$(
  grep -v '^#\|^$' "$ENV_FILE" |  # Игнорируем комментарии и пустые строки
  grep -oE '^[A-Z_]+=' |          # Выбираем строки с объявлениями переменных
  cut -d= -f1 |                   # Извлекаем имена переменных
  sed 's/^/\${/' | sed 's/$/}/' | # Преобразуем в формат ${VAR}
  tr '\n' ',' |                   # Объединяем через запятую
  sed 's/,$//'                    # Удаляем последнюю запятую
)

# Подставляем только указанные переменные в конфиги
envsubst "$VARS_TO_SUBST" < /etc/nginx/nginx.template.conf > /etc/nginx/nginx.conf
envsubst "$VARS_TO_SUBST" < /etc/nginx/vpn_stealth.template.conf > /etc/nginx/conf.d/default.conf

# Дополнительные проверки (можно закомментировать)
echo "=== Substituted variables ==="
echo "$VARS_TO_SUBST" | tr ',' '\n'
echo "============================="

# Права на файлы
chmod 644 /etc/nginx/nginx.conf
chmod 644 /etc/nginx/conf.d/default.conf

# Запуск nginx
exec nginx -g 'daemon off;'