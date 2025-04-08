**VoVOneVPN** — это набор VPN-сервисов, использующая Docker, Nginx, X-UI и Pritunl для безопасного подключения.

## Описание

Проект предназначен для настройки безопасного VPN-соединения с использованием Docker-контейнеров. Он включает в себя конфигурации для Nginx (как обратного прокси), X-UI для управления подписками и Pritunl для L2TP/IPSec VPN и других протоколов (при необходисмости).

## Структура проекта

* **docker-compose.yml** — основной файл для запуска всех сервисов с помощью Docker Compose
* **nginx** — конфигурации для Nginx, включая настройки для обратного проксирования и защиты трафика
* **3x-ui** — конфигурации для [3x-UI](https://github.com/MHSanaEi/3x-ui), интерфейса управления подписками
* **pritunl** — конфигурации для [Pritunl](https://github.com/pritunl/pritunl), VPN-сервера
* **deploy.sh** — развертывание проекта через Docker Compose
    - **scripts/** — набор вспомогательных скриптов для развертывания
* **reset_docker.sh** — безопасное удаление контейнеров и очистка Docker-среды для проекта

## Установка

### Способ 1: Использование скрипта deploy.sh

1. Клонируйте репозиторий:
   
```bash
   git clone https://github.com/yourusername/VoVOneVPN.git
```
Запустите скрипт **deploy.sh**:

```bash
cd ./VoVOneVPN
chmod +x deploy.sh
./deploy.sh
```
### Способ 2: Ручной запуск через Docker Compose
1. Клонируйте репозиторий:

```bash
git clone https://github.com/yourusername/VoVOneVPN.git
cd ./VoVOneVPN
docker-compose up -d --project-name "vovonevpn"
```

## Удаление
Для полного удаления проекта:

```bash
cd ./VoVOneVPN
chmod +x reset_docker.sh
./reset_docker.sh
```

## Конфигурация
Nginx настроен с SSL-сертификатами Let's Encrypt

3x-UI и Pritunl работают через HTTPS

Автоматическое обновление сертификатов через скрипт **"/vovOneVPN/scripts/duckdns_updater/duckdns_updater.sh"**

## Лицензия
Проект распространяется под лицензией MIT.
