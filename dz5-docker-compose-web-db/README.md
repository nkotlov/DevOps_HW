# ДЗ 5. Docker Compose: Nginx + PostgreSQL

## Задание

Необходимо написать `docker compose` конфиг для разворачивания двух контейнеров в одной сети `10.10.10.0/28` типа `bridge`:

- `Nginx` или `Apache` + самописное web-приложение;
- `MySQL` или `PostgreSQL`.

Дополнительные требования:

- web-приложению должны передаваться конфигурационные файлы через volume;
- Nginx должен быть открыт на `80` порту внутри контейнера;
- Nginx должен быть доступен с хостовой машины по порту `8080`;
- каталог хранения данных БД должен монтироваться как Docker volume;
- Docker volume должен быть описан в том же `docker-compose.yml`;
- сервис с БД должен быть доступен из контейнера с веб-сервером по именам `new_db` и `dev_db`;
- должна быть задана очередность запуска сервисов.

## Что реализовано

В работе реализован `docker-compose.yml`, который поднимает два контейнера:

| Сервис | Контейнер | Назначение |
|---|---|---|
| `web` | `dz5_nginx_web` | Nginx + простая GET-заглушка |
| `db` | `dz5_postgres_db` | PostgreSQL |

Оба контейнера находятся в одной bridge-сети:

```text
10.10.10.0/28
```

Для PostgreSQL задан Docker volume:

```text
dz5_postgres_data
```

База данных доступна из контейнера `web` по двум именам:

```text
new_db
dev_db
```

Очередность запуска задана через `depends_on` и `healthcheck`: контейнер `web` запускается после того, как контейнер `db` становится `healthy`.

## Структура проекта

```text
dz5-docker-compose-web-db/
├── README.md
├── docker-compose.yml
├── app/
│   └── index.html
├── nginx/
│   └── default.conf
├── db/
│   └── init.sql
└── screenshots/
    ├── 01_project_files.png
    ├── 02_compose_config_part1.png
    ├── 02_compose_config_part2.png
    ├── 03_compose_up_ps.png
    ├── 04_network_check.png
    ├── 05_nginx_host_check.png
    ├── 06_db_aliases_from_web.png
    ├── 07_postgres_check.png
    └── 08_volume_check.png
```

## Файлы работы

| Файл / папка | Назначение |
|---|---|
| `docker-compose.yml` | Основной Docker Compose конфиг |
| `app/index.html` | Простая GET-заглушка для Nginx |
| `nginx/default.conf` | Конфигурационный файл Nginx, передаваемый через volume |
| `db/init.sql` | SQL-скрипт инициализации PostgreSQL |
| `screenshots/` | Скриншоты выполнения и проверки результата |

## Docker Compose конфигурация

В `docker-compose.yml` описаны два сервиса: `web` и `db`.

Сервис `web` использует образ:

```text
nginx:1.27-alpine
```

Для Nginx проброшен порт:

```text
8080:80
```

Это означает, что Nginx работает на `80` порту внутри контейнера и доступен с хостовой машины по адресу:

```text
http://localhost:8080
```

Конфигурационный файл Nginx передаётся в контейнер через volume:

```yaml
./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
```

Файлы web-приложения также передаются через volume:

```yaml
./app:/usr/share/nginx/html:ro
```

Сервис `db` использует образ:

```text
postgres:15
```

Для хранения данных PostgreSQL используется Docker volume:

```yaml
postgres_data:/var/lib/postgresql/data
```

Volume описан в этом же `docker-compose.yml`:

```yaml
volumes:
  postgres_data:
    name: dz5_postgres_data
```

## Сеть

В Compose-файле описана bridge-сеть:

```yaml
networks:
  app_net:
    name: dz5_app_net
    driver: bridge
    ipam:
      config:
        - subnet: 10.10.10.0/28
```

Контейнеры получили адреса:

| Контейнер | IP |
|---|---|
| `dz5_nginx_web` | `10.10.10.2` |
| `dz5_postgres_db` | `10.10.10.3` |

Для БД заданы сетевые alias:

```yaml
aliases:
  - new_db
  - dev_db
```

Это позволяет обращаться к PostgreSQL из контейнера `web` по именам `new_db` и `dev_db`.

## Очередность запуска

Очередность запуска задана через `depends_on`:

```yaml
depends_on:
  db:
    condition: service_healthy
```

Для PostgreSQL настроен `healthcheck`:

```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U devuser -d devdb"]
  interval: 5s
  timeout: 3s
  retries: 5
```

Благодаря этому контейнер `web` запускается после того, как контейнер `db` становится доступным.

## Создание файлов

Структура проекта была проверена командой:

```bash
tree .
```

Скриншот:

[01_project_files.png](screenshots/01_project_files.png)

На скриншоте видно, что созданы файлы `docker-compose.yml`, `app/index.html`, `nginx/default.conf`, `db/init.sql` и папка `screenshots`.

## Проверка Compose-конфига

Проверка итоговой конфигурации выполнялась командой:

```bash
docker compose config
```

Так как вывод получился длинным, результат сохранён в двух скриншотах:

[02_compose_config_part1.png](screenshots/02_compose_config_part1.png)

[02_compose_config_part2.png](screenshots/02_compose_config_part2.png)

На скриншотах видно:

- сервисы `web` и `db`;
- сеть `dz5_app_net`;
- subnet `10.10.10.0/28`;
- volume `dz5_postgres_data`;
- alias для БД: `new_db`, `dev_db`;
- проброс порта `8080:80`;
- bind mount конфигурации Nginx.

## Запуск контейнеров

Перед запуском старые контейнеры и volume удалялись командой:

```bash
docker compose down -v
```

Запуск выполнялся командой:

```bash
docker compose up -d
```

Проверка запущенных контейнеров:

```bash
docker compose ps -a
```

Скриншот:

[03_compose_up_ps.png](screenshots/03_compose_up_ps.png)

На скриншоте видно, что запущены два контейнера:

- `dz5_nginx_web`;
- `dz5_postgres_db`.

Также видно, что Nginx доступен с хоста по порту `8080`.

## Проверка сети

Проверка сети выполнялась командами:

```bash
docker network inspect dz5_app_net --format 'Subnet: {{range .IPAM.Config}}{{.Subnet}}{{end}}'
docker inspect dz5_nginx_web --format 'web IP: {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
docker inspect dz5_postgres_db --format 'db IP: {{range .NetworkSettings.Networks}}{{.IPAddress}} aliases={{.Aliases}}{{end}}'
```

Скриншот:

[04_network_check.png](screenshots/04_network_check.png)

На скриншоте видно:

```text
Subnet: 10.10.10.0/28
web IP: 10.10.10.2
db IP: 10.10.10.3
aliases=[dz5_postgres_db db new_db dev_db]
```

Это подтверждает, что контейнеры находятся в одной bridge-сети и что для БД заданы имена `new_db` и `dev_db`.

## Проверка Nginx

Работа Nginx проверялась с хостовой машины командой:

```bash
wget -qO- http://localhost:8080
```

Скриншот:

[05_nginx_host_check.png](screenshots/05_nginx_host_check.png)

В результате была получена HTML-страница с текстом:

```text
Docker Compose Web App
GET-заглушка работает через Nginx.
```

Это подтверждает, что Nginx работает и доступен с хостовой машины по порту `8080`.

## Проверка доступности БД из web-контейнера

Проверка доступности БД по именам `new_db` и `dev_db` выполнялась из контейнера `web`:

```bash
docker compose exec web sh -c "getent hosts new_db && getent hosts dev_db"
```

Скриншот:

[06_db_aliases_from_web.png](screenshots/06_db_aliases_from_web.png)

На скриншоте видно, что оба имени резолвятся в IP-адрес PostgreSQL-контейнера:

```text
10.10.10.3 new_db
10.10.10.3 dev_db
```

Это подтверждает выполнение требования о доступности БД из контейнера с веб-сервером по именам `new_db` и `dev_db`.

## Проверка PostgreSQL

Работа PostgreSQL проверялась командой:

```bash
docker compose exec -e PGPASSWORD=devpass db psql -U devuser -d devdb -c "SELECT * FROM app_info;"
```

Скриншот:

[07_postgres_check.png](screenshots/07_postgres_check.png)

В результате был получен ответ из таблицы `app_info`:

```text
PostgreSQL works in Docker Compose
```

Это подтверждает, что PostgreSQL работает, база данных создана, а SQL-скрипт `db/init.sql` был выполнен.

## Проверка Docker volume

Проверка volume выполнялась командой:

```bash
docker volume inspect dz5_postgres_data
```

Скриншот:

[08_volume_check.png](screenshots/08_volume_check.png)

На скриншоте видно, что создан Docker volume:

```text
dz5_postgres_data
```

Этот volume используется для хранения данных PostgreSQL.

## Проверка соответствия заданию

| Требование | Выполнение |
|---|---|
| Развернуть два контейнера | Созданы `dz5_nginx_web` и `dz5_postgres_db` |
| Использовать bridge-сеть `10.10.10.0/28` | Создана сеть `dz5_app_net` с subnet `10.10.10.0/28` |
| Использовать Nginx или Apache | Используется Nginx |
| Добавить web-приложение / GET-заглушку | Используется `app/index.html` |
| Передать конфигурационные файлы через volume | `nginx/default.conf` передаётся через bind mount |
| Открыть Nginx на 80 порту | В контейнере Nginx слушает порт `80` |
| Сделать Nginx доступным на хосте по 8080 | Используется проброс `8080:80` |
| Использовать MySQL или PostgreSQL | Используется PostgreSQL |
| Хранить данные БД через Docker volume | Используется `dz5_postgres_data` |
| Описать volume в том же Compose-файле | Volume описан в `docker-compose.yml` |
| Сделать БД доступной по `new_db`, `dev_db` | Для `db` заданы aliases `new_db` и `dev_db` |
| Задать очередность запуска | Используется `depends_on` и `healthcheck` |

## Скриншоты

| № | Скриншот | Что подтверждает |
|---|---|---|
| 1 | [01_project_files.png](screenshots/01_project_files.png) | Создана структура проекта |
| 2 | [02_compose_config_part1.png](screenshots/02_compose_config_part1.png) | Часть итоговой Compose-конфигурации |
| 3 | [02_compose_config_part2.png](screenshots/02_compose_config_part2.png) | Сеть, volume и проброс портов в Compose-конфиге |
| 4 | [03_compose_up_ps.png](screenshots/03_compose_up_ps.png) | Контейнеры запущены |
| 5 | [04_network_check.png](screenshots/04_network_check.png) | Проверка сети, IP-адресов и alias |
| 6 | [05_nginx_host_check.png](screenshots/05_nginx_host_check.png) | Nginx доступен с хоста по порту `8080` |
| 7 | [06_db_aliases_from_web.png](screenshots/06_db_aliases_from_web.png) | БД доступна из web-контейнера по `new_db` и `dev_db` |
| 8 | [07_postgres_check.png](screenshots/07_postgres_check.png) | PostgreSQL работает |
| 9 | [08_volume_check.png](screenshots/08_volume_check.png) | Docker volume для БД создан |

## Вывод

В результате был написан `docker-compose.yml`, который разворачивает два контейнера: `Nginx` с простой GET-заглушкой и `PostgreSQL`. Контейнеры работают в одной bridge-сети `10.10.10.0/28`. Nginx доступен с хостовой машины по порту `8080`, а его конфигурационный файл передаётся через volume. Для PostgreSQL создан Docker volume `dz5_postgres_data`, описанный в том же Compose-файле. База данных доступна из контейнера `web` по именам `new_db` и `dev_db`. Очередность запуска сервисов задана через `depends_on` и `healthcheck`.