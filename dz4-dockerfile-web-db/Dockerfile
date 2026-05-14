# Используется базовый образ PostgreSQL.
FROM postgres:15

# Информация об авторе образа.
MAINTAINER NKotlov

# Переменные окружения для PostgreSQL.
ENV POSTGRES_USER=devuser
ENV POSTGRES_PASSWORD=devpass
ENV POSTGRES_DB=devdb

# Работа выполняется от root для установки и запуска nginx.
USER root

# Установка веб-сервера nginx.
RUN apt-get update && \
    apt-get install -y nginx && \
    rm -rf /var/lib/apt/lists/*

# Рабочая директория контейнера.
WORKDIR /app

# Копирование HTML-страницы для nginx.
COPY index.html /var/www/html/index.html

# Копирование скрипта запуска.
COPY start.sh /app/start.sh

# Добавление SQL-скрипта инициализации PostgreSQL.
ADD init.sql /docker-entrypoint-initdb.d/init.sql

# Выдача прав на запуск скрипта.
RUN chmod +x /app/start.sh

# Volume для хранения данных PostgreSQL.
VOLUME ["/var/lib/postgresql/data"]

# Открытие портов nginx и PostgreSQL.
EXPOSE 80
EXPOSE 5432

# Запуск nginx и PostgreSQL.
CMD ["/app/start.sh"]