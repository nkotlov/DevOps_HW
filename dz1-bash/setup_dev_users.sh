#!/bin/bash

set -euo pipefail

LOG_FILE="./setup_dev_users.log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "========================================"
echo "Запуск скрипта: $(date)"
echo "========================================"

if [[ "$EUID" -ne 0 ]]; then
    echo "Ошибка: скрипт нужно запускать через sudo."
    echo "Пример: sudo ./setup_dev_users.sh -d /opt/dev_workdirs"
    exit 1
fi

BASE_DIR=""

while getopts "d:" opt; do
    case "$opt" in
        d)
            BASE_DIR="$OPTARG"
            ;;
        *)
            echo "Использование: sudo ./setup_dev_users.sh -d /path/to/workdirs"
            exit 1
            ;;
    esac
done

if [[ -z "$BASE_DIR" ]]; then
    read -rp "Введите путь для создания рабочих директорий: " BASE_DIR
fi

if [[ -z "$BASE_DIR" ]]; then
    echo "Ошибка: путь не может быть пустым."
    exit 1
fi

if ! command -v setfacl >/dev/null 2>&1; then
    echo "Ошибка: setfacl не найден. Установите пакет acl."
    exit 1
fi

echo "Базовая директория: $BASE_DIR"

echo "Создание группы dev..."
if getent group dev >/dev/null; then
    echo "Группа dev уже существует."
else
    groupadd dev
    echo "Группа dev создана."
fi

echo "Настройка sudo без пароля для группы dev..."
SUDOERS_FILE="/etc/sudoers.d/dev-nopasswd"

echo "%dev ALL=(ALL) NOPASSWD:ALL" > "$SUDOERS_FILE"
chmod 440 "$SUDOERS_FILE"

visudo -cf "$SUDOERS_FILE"
echo "Файл sudoers проверен успешно."

echo "Создание базовой директории..."
mkdir -p "$BASE_DIR"

echo "Поиск несистемных пользователей..."
USERS=$(awk -F: '$3 >= 1000 && $3 < 65534 && $1 != "nobody" {print $1}' /etc/passwd)

if [[ -z "$USERS" ]]; then
    echo "Несистемные пользователи не найдены."
    exit 0
fi

echo "Найдены несистемные пользователи:"
echo "$USERS"

for USERNAME in $USERS; do
    echo "----------------------------------------"
    echo "Обработка пользователя: $USERNAME"

    USER_GROUP=$(id -gn "$USERNAME")
    WORKDIR="$BASE_DIR/${USERNAME}_workdir"

    echo "Добавление пользователя $USERNAME в группу dev..."
    usermod -aG dev "$USERNAME"

    echo "Создание директории $WORKDIR..."
    mkdir -p "$WORKDIR"

    echo "Назначение владельца и группы: $USERNAME:$USER_GROUP"
    chown "$USERNAME:$USER_GROUP" "$WORKDIR"

    echo "Установка прав 660..."
    chmod 660 "$WORKDIR"

    echo "Добавление права чтения для группы dev через ACL..."
    setfacl -m g:dev:r-- "$WORKDIR"

    echo "Права директории:"
    ls -ld "$WORKDIR"

    echo "ACL директории:"
    getfacl "$WORKDIR"
done

echo "----------------------------------------"
echo "Проверка группы dev:"
getent group dev

echo "----------------------------------------"
echo "Скрипт завершён успешно."
echo "Лог сохранён в файл: $LOG_FILE"