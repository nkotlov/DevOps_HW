# ДЗ 2. Ansible playbook

## Задание

Необходимо написать Ansible playbook, который на удалённой машине выполняет следующие действия:

- создаёт пользователя;
- выдаёт пользователю права `sudo`;
- настраивает авторизацию SSH по ключам для пользователя;
- отключает авторизацию по паролю при SSH-подключении;
- создаёт директорию в `/opt/` с правами `660` для пользователя.

## Файлы работы

В работе используются следующие файлы:

- `ansible.cfg` — базовая конфигурация Ansible;
- `inventory.ini` — список удалённых хостов;
- `playbook.yml` — основной Ansible playbook;
- `files/devopsuser_key.pub` — публичный SSH-ключ для нового пользователя;
- `screenshots/` — скриншоты выполнения и проверки результата.

## Стенд

Работа выполнялась на двух виртуальных машинах Ubuntu:

- `Ubuntu-Control` — управляющая машина, с которой запускался Ansible;
- `Ubuntu-Target` — удалённая машина, на которую применялся playbook.

Используемые адреса:

- `Ubuntu-Control`: `192.168.100.10`;
- `Ubuntu-Target`: `192.168.100.20`.

Перед выполнением задания была проверена доступность удалённой машины:

```bash
ping -c 4 192.168.100.20
```

Скриншот проверки сети:

[01_network_ping_control_to_target.png](screenshots/01_network_ping_control_to_target.png)

## Подготовка SSH-доступа для Ansible

Для подключения Ansible к удалённой машине был создан SSH-ключ:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/ansible_control_key -C "ansible-control"
```

Проверка созданного ключа:

```bash
ls -l ~/.ssh/ansible_control_key*
```

Скриншот:

[02_ansible_control_key.png](screenshots/02_ansible_control_key.png)

После этого был проверен SSH-вход на удалённую машину:

```bash
ssh -i ~/.ssh/ansible_control_key user@192.168.100.20
```

Скриншоты проверки SSH-подключения:

[03a_ssh_login_to_target.png](screenshots/03a_ssh_login_to_target.png)

[03b_ssh_hostname_whoami.png](screenshots/03b_ssh_hostname_whoami.png)

На втором скриншоте видно, что подключение выполнено к машине `ansible-target` под пользователем `user`.

## Подготовка ключа для нового пользователя

Для пользователя `devopsuser`, которого создаёт playbook, был создан отдельный SSH-ключ:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/devopsuser_key -C "devopsuser-key"
```

Публичный ключ был сохранён в файл:

```text
files/devopsuser_key.pub
```

Скриншот:

[04_devopsuser_key_created.png](screenshots/04_devopsuser_key_created.png)

## Inventory

В файле `inventory.ini` был описан удалённый хост:

```ini
[target]
ansible-target ansible_host=192.168.100.20 ansible_user=user ansible_ssh_private_key_file=/home/user/.ssh/ansible_control_key
```

Проверка подключения Ansible к удалённой машине выполнялась командой:

```bash
ansible -i inventory.ini target -m ping
```

Результат проверки:

[05_ansible_ping.png](screenshots/05_ansible_ping.png)

## Запуск playbook

Playbook запускался командой:

```bash
ansible-playbook -i inventory.ini playbook.yml -K
```

Ключ `-K` использовался для ввода пароля `sudo` пользователя `user` на удалённой машине.

Во время выполнения playbook были выполнены основные задачи:

- создание группы для пользователя;
- создание пользователя `devopsuser`;
- выдача пользователю `sudo`-прав без пароля;
- добавление SSH-ключа для пользователя;
- отключение SSH-авторизации по паролю;
- перезапуск SSH-сервиса;
- создание директории в `/opt`.

Скриншоты запуска playbook:

[06a_playbook_run_tasks.png](screenshots/06a_playbook_run_tasks.png)

[06b_playbook_run_recap.png](screenshots/06b_playbook_run_recap.png)

На итоговом скриншоте видно, что playbook завершился без ошибок:

```text
failed=0
```

## Проверка результата

### 1. Создание пользователя

Проверка пользователя выполнялась командой:

```bash
ansible -i inventory.ini target -m command -a "id devopsuser" -b -K
```

Результат показывает, что пользователь `devopsuser` создан на удалённой машине.

Скриншот:

[07_user_created.png](screenshots/07_user_created.png)

### 2. Выдача sudo-прав

Проверка sudoers-файла выполнялась командой:

```bash
ansible -i inventory.ini target -m command -a "cat /etc/sudoers.d/devopsuser" -b -K
```

В результате было получено правило:

```text
devopsuser ALL=(ALL) NOPASSWD:ALL
```

Это подтверждает, что пользователь `devopsuser` получил права `sudo` без запроса пароля.

Скриншот:

[08_sudo_rights.png](screenshots/08_sudo_rights.png)

### 3. SSH-авторизация по ключу

После выполнения playbook был проверен вход под новым пользователем по SSH-ключу:

```bash
ssh -i ~/.ssh/devopsuser_key devopsuser@192.168.100.20
```

Скриншот подключения:

[09a_ssh_key_login_devopsuser.png](screenshots/09a_ssh_key_login_devopsuser.png)

Внутри SSH-сессии были выполнены команды:

```bash
whoami
hostname
```

Результат показал, что вход выполнен под пользователем `devopsuser` на машине `ansible-target`.

Скриншот:

[09b_ssh_key_login_devopsuser_check.png](screenshots/09b_ssh_key_login_devopsuser_check.png)

### 4. Отключение SSH-входа по паролю

Проверка выполнялась командой:

```bash
ansible -i inventory.ini target -m shell -a "sshd -T | grep -E 'passwordauthentication|kbdinteractiveauthentication'" -b -K
```

Результат:

```text
passwordauthentication no
kbdinteractiveauthentication no
```

Это подтверждает, что авторизация по паролю при SSH-подключении отключена.

Скриншот:

[10_password_auth_disabled.png](screenshots/10_password_auth_disabled.png)

### 5. Создание директории в `/opt`

Проверка директории выполнялась командой:

```bash
ansible -i inventory.ini target -m command -a "ls -ld /opt/devopsuser_workdir" -b -K
```

Результат:

```text
drw-rw---- 2 devopsuser devopsuser ... /opt/devopsuser_workdir
```

Это означает, что директория создана в `/opt`, имеет права `660`, владельцем является `devopsuser`, группой также является `devopsuser`.

Скриншот:

[11_opt_directory_permissions.png](screenshots/11_opt_directory_permissions.png)

## Как работает playbook

Playbook применяется к группе хостов `target`, которая описана в файле `inventory.ini`.

Сначала Ansible подключается к удалённой машине `ansible-target` по SSH под существующим пользователем `user`. Для повышения прав используется `become: true`.

Далее playbook создаёт группу и пользователя `devopsuser`. После этого для пользователя создаётся sudoers-файл:

```text
/etc/sudoers.d/devopsuser
```

В этот файл записывается правило:

```text
devopsuser ALL=(ALL) NOPASSWD:ALL
```

Затем playbook добавляет публичный SSH-ключ из файла `files/devopsuser_key.pub` в `authorized_keys` пользователя `devopsuser`. Это позволяет подключаться к удалённой машине под новым пользователем по SSH-ключу.

После настройки ключа playbook отключает SSH-авторизацию по паролю. Для этого задаются параметры:

```text
PasswordAuthentication no
KbdInteractiveAuthentication no
```

После изменения SSH-настроек сервис `ssh` перезапускается.

В конце playbook создаёт директорию:

```text
/opt/devopsuser_workdir
```

Для неё назначаются владелец `devopsuser`, группа `devopsuser` и права `660`.

## Скриншоты

| № | Скриншот | Что подтверждает |
|---|---|---|
| 1 | [01_network_ping_control_to_target.png](screenshots/01_network_ping_control_to_target.png) | Удалённая машина доступна по сети |
| 2 | [02_ansible_control_key.png](screenshots/02_ansible_control_key.png) | Создан SSH-ключ для подключения Ansible |
| 3 | [03a_ssh_login_to_target.png](screenshots/03a_ssh_login_to_target.png) | SSH-подключение к удалённой машине работает |
| 4 | [03b_ssh_hostname_whoami.png](screenshots/03b_ssh_hostname_whoami.png) | Подключение выполнено к `ansible-target` |
| 5 | [04_devopsuser_key_created.png](screenshots/04_devopsuser_key_created.png) | Создан SSH-ключ для нового пользователя |
| 6 | [05_ansible_ping.png](screenshots/05_ansible_ping.png) | Ansible успешно подключается к удалённой машине |
| 7 | [06a_playbook_run_tasks.png](screenshots/06a_playbook_run_tasks.png) | Playbook выполняет задачи настройки |
| 8 | [06b_playbook_run_recap.png](screenshots/06b_playbook_run_recap.png) | Playbook завершился без ошибок |
| 9 | [07_user_created.png](screenshots/07_user_created.png) | Пользователь `devopsuser` создан |
| 10 | [08_sudo_rights.png](screenshots/08_sudo_rights.png) | Пользователю выданы sudo-права |
| 11 | [09a_ssh_key_login_devopsuser.png](screenshots/09a_ssh_key_login_devopsuser.png) | SSH-вход под новым пользователем по ключу работает |
| 12 | [09b_ssh_key_login_devopsuser_check.png](screenshots/09b_ssh_key_login_devopsuser_check.png) | Вход выполнен под пользователем `devopsuser` |
| 13 | [10_password_auth_disabled.png](screenshots/10_password_auth_disabled.png) | SSH-авторизация по паролю отключена |
| 14 | [11_opt_directory_permissions.png](screenshots/11_opt_directory_permissions.png) | Директория в `/opt` создана с правами `660` |

## Вывод

В результате был написан Ansible playbook, который на удалённой машине создал пользователя `devopsuser`, выдал ему права `sudo`, настроил SSH-авторизацию по ключу, отключил SSH-вход по паролю и создал директорию `/opt/devopsuser_workdir` с правами `660`.
