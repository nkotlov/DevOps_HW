# ДЗ 4. Dockerfile: Nginx + PostgreSQL

## Задание

Необходимо написать `Dockerfile` для создания Docker-образа, который содержит:

- веб-сервер Apache или Nginx;
- базу данных MySQL или PostgreSQL.

В `Dockerfile` должны использоваться инструкции:

- `FROM`;
- `MAINTAINER`;
- `RUN`;
- `CMD`;
- `WORKDIR`;
- `ENV`;
- `ADD`;
- `COPY`;
- `VOLUME`;
- `USER`;
- `EXPOSE`.

Также `Dockerfile` должен содержать комментарии с пояснениями того, что делается.

Собранный образ должен иметь имя вида:

```text
<фамилия>_<инициалы>_image_<текущая дата>
```

Рядом с `Dockerfile` должен быть скриншот, на котором видны все слои image, их размер на диске и команда, которой это было выведено.

## Что реализовано

В работе создан Docker-образ на базе `postgres:15`.

Внутри образа:

- используется PostgreSQL как база данных;
- дополнительно устанавливается веб-сервер Nginx;
- копируется HTML-страница для проверки работы веб-сервера;
- добавляется SQL-скрипт инициализации базы данных;
- используется скрипт `start.sh`, который запускает Nginx и PostgreSQL.

Имя собранного образа:

```text
kotlov_na_image_20260514
```

## Файлы работы

| Файл / папка | Назначение |
|---|---|
| `Dockerfile` | Основной файл для сборки Docker-образа |
| `index.html` | HTML-страница для проверки Nginx |
| `init.sql` | SQL-скрипт для инициализации PostgreSQL |
| `start.sh` | Скрипт запуска Nginx и PostgreSQL |
| `image_layers_part1.png` | Скриншот первой части слоёв Docker image |
| `image_layers_part2.png` | Скриншот второй части слоёв Docker image |
| `screenshots/` | Скриншоты выполнения и проверки результата |

## Структура проекта

```text
dz4-dockerfile-web-db/
├── README.md
├── Dockerfile
├── index.html
├── init.sql
├── start.sh
├── image_layers_part1.png
├── image_layers_part2.png
└── screenshots/
    ├── 01_project_files.png
    ├── 02_image_build.png
    ├── 03_container_running.png
    ├── 04_nginx_check.png
    └── 05_postgres_check.png
```

## Dockerfile

В `Dockerfile` использованы все инструкции, указанные в задании:

| Инструкция | Назначение |
|---|---|
| `FROM` | Используется базовый образ `postgres:15` |
| `MAINTAINER` | Указан автор образа |
| `ENV` | Заданы переменные окружения PostgreSQL |
| `USER` | Указан пользователь `root` для установки Nginx |
| `RUN` | Устанавливается Nginx и выдаются права на запуск скрипта |
| `WORKDIR` | Установлена рабочая директория `/app` |
| `COPY` | Копируются `index.html` и `start.sh` |
| `ADD` | Добавляется `init.sql` в директорию инициализации PostgreSQL |
| `VOLUME` | Задан volume для данных PostgreSQL |
| `EXPOSE` | Открыты порты `80` и `5432` |
| `CMD` | Задан запуск скрипта `/app/start.sh` |

## Создание файлов

Рабочая папка создавалась командой:

```bash
mkdir -p ~/dz4-dockerfile-web-db/screenshots
cd ~/dz4-dockerfile-web-db
```

После создания файлов была выполнена проверка:

```bash
ls -la
```

Скриншот:

[01_project_files.png](screenshots/01_project_files.png)

На скриншоте видно, что в папке находятся файлы `Dockerfile`, `index.html`, `init.sql`, `start.sh` и папка `screenshots`.

## Сборка Docker-образа

Для имени образа была задана переменная:

```bash
export IMAGE_NAME=kotlov_na_image_$(date +%Y%m%d)
```

Сборка выполнялась командой:

```bash
docker build -t $IMAGE_NAME .
```

Проверка созданного образа:

```bash
docker images | grep kotlov
```

Скриншот:

[02_image_build.png](screenshots/02_image_build.png)

На скриншоте видно, что был создан образ:

```text
kotlov_na_image_20260514
```

## Просмотр слоёв Docker image

Для просмотра слоёв image и их размеров использовалась команда:

```bash
docker history --human --format "table {{.ID}}\t{{.Size}}\t{{.CreatedBy}}" $IMAGE_NAME
```

Так как вывод команды получился длинным, результат сохранён в двух скриншотах:

[image_layers_part1.png](image_layers_part1.png)

[image_layers_part2.png](image_layers_part2.png)

На скриншотах видны слои Docker image, их размер и команда, которой был получен вывод.

## Запуск контейнера

Перед запуском старый контейнер с таким именем удалялся, если он существовал:

```bash
docker rm -f dz4_web_db 2>/dev/null || true
```

Контейнер запускался командой:

```bash
docker run -d --name dz4_web_db -p 8080:80 -p 5433:5432 $IMAGE_NAME
```

Проверка запущенного контейнера:

```bash
docker ps
```

Скриншот:

[03_container_running.png](screenshots/03_container_running.png)

На скриншоте видно, что контейнер `dz4_web_db` запущен, а порты проброшены:

```text
8080 -> 80
5433 -> 5432
```

## Проверка Nginx

Работа веб-сервера проверялась командой:

```bash
wget -qO- http://localhost:8080
```

Скриншот:

[04_nginx_check.png](screenshots/04_nginx_check.png)

В результате была получена HTML-страница с текстом:

```text
Docker image with Nginx and PostgreSQL
```

Это подтверждает, что Nginx работает внутри контейнера.

## Проверка PostgreSQL

Работа PostgreSQL проверялась командой:

```bash
docker exec -e PGPASSWORD=devpass dz4_web_db psql -U devuser -d devdb -c "SELECT * FROM app_info;"
```

Скриншот:

[05_postgres_check.png](screenshots/05_postgres_check.png)

В результате был получен ответ из таблицы `app_info`:

```text
PostgreSQL initialized inside Docker image
```

Это подтверждает, что PostgreSQL работает, база данных создана, а SQL-скрипт `init.sql` был выполнен.

## Проверка соответствия заданию

| Требование | Выполнение |
|---|---|
| Образ содержит веб-сервер | Используется Nginx |
| Образ содержит базу данных | Используется PostgreSQL |
| Использована инструкция `FROM` | Есть в `Dockerfile` |
| Использована инструкция `MAINTAINER` | Есть в `Dockerfile` |
| Использована инструкция `RUN` | Есть в `Dockerfile` |
| Использована инструкция `CMD` | Есть в `Dockerfile` |
| Использована инструкция `WORKDIR` | Есть в `Dockerfile` |
| Использована инструкция `ENV` | Есть в `Dockerfile` |
| Использована инструкция `ADD` | Есть в `Dockerfile` |
| Использована инструкция `COPY` | Есть в `Dockerfile` |
| Использована инструкция `VOLUME` | Есть в `Dockerfile` |
| Использована инструкция `USER` | Есть в `Dockerfile` |
| Использована инструкция `EXPOSE` | Есть в `Dockerfile` |
| Dockerfile содержит комментарии | Комментарии добавлены |
| Имя образа соответствует шаблону | `kotlov_na_image_20260514` |
| Есть скриншот слоёв image и размеров | `image_layers_part1.png`, `image_layers_part2.png` |

## Скриншоты

| № | Скриншот | Что подтверждает |
|---|---|---|
| 1 | [01_project_files.png](screenshots/01_project_files.png) | Созданы файлы задания |
| 2 | [02_image_build.png](screenshots/02_image_build.png) | Docker image создан и имеет имя по шаблону |
| 3 | [image_layers_part1.png](image_layers_part1.png) | Видны слои image и размеры |
| 4 | [image_layers_part2.png](image_layers_part2.png) | Видна оставшаяся часть слоёв image |
| 5 | [03_container_running.png](screenshots/03_container_running.png) | Контейнер запущен |
| 6 | [04_nginx_check.png](screenshots/04_nginx_check.png) | Nginx работает |
| 7 | [05_postgres_check.png](screenshots/05_postgres_check.png) | PostgreSQL работает |

## Вывод

В результате был написан `Dockerfile`, который создаёт Docker-образ с веб-сервером Nginx и базой данных PostgreSQL. В `Dockerfile` использованы все инструкции, указанные в задании: `FROM`, `MAINTAINER`, `RUN`, `CMD`, `WORKDIR`, `ENV`, `ADD`, `COPY`, `VOLUME`, `USER`, `EXPOSE`. Образ был собран с именем `kotlov_na_image_20260514`, контейнер успешно запущен, работа Nginx и PostgreSQL проверена командами `wget` и `psql`. Дополнительно был получен вывод слоёв Docker image с их размерами через команду `docker history`.