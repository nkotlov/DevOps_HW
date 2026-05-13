# ДЗ 3. Ansible roles

## Задание

Необходимо выполнить ту же постановку задачи, что и в задании с Ansible playbook, но с дополнительными требованиями:

- реализовать решение как несколько Ansible roles;
- задачи по пользователю вынести в отдельную роль;
- настройки SSH вынести в отдельную роль;
- создаваемые пользователи и их открытые ключи для авторизации определить через `vars`;
- добавить тестирование ролей через Molecule;
- для Molecule использовать Docker driver/provider.

## Что реализовано

Решение разделено на две Ansible-роли:

| Роль | Назначение |
|---|---|
| `user_management` | Создание пользователей, групп, sudo-прав, SSH-ключей и директорий в `/opt` |
| `ssh_hardening` | Настройка SSH и отключение авторизации по паролю |

Пользователь `roleuser` и его публичный SSH-ключ определены через переменные в файле `group_vars/all.yml`.

Для тестирования ролей настроен Molecule-сценарий с Docker driver.

## Структура проекта

```text
dz3-ansible-roles/
├── README.md
├── ansible.cfg
├── inventory.ini
├── playbook.yml
├── group_vars/
│   └── all.yml
├── roles/
│   ├── user_management/
│   │   └── tasks/
│   │       └── main.yml
│   └── ssh_hardening/
│       ├── defaults/
│       │   └── main.yml
│       ├── handlers/
│       │   └── main.yml
│       └── tasks/
│           └── main.yml
├── molecule/
│   └── default/
│       ├── Dockerfile.j2
│       ├── molecule.yml
│       ├── converge.yml
│       └── verify.yml
└── screenshots/
```

Скриншот структуры проекта: [03_project_structure.png](screenshots/03_project_structure.png)

## Стенд

Работа выполнялась на двух виртуальных машинах Ubuntu:

| Машина | Назначение | IP |
|---|---|---|
| `Ubuntu-Control` | Управляющая машина с Ansible, Molecule и Docker | `192.168.100.10` |
| `Ubuntu-Target` | Удалённая машина, на которую применялись роли | `192.168.100.20` |

Перед запуском ролей была проверена доступность удалённой машины через Ansible:

```bash
ansible -i inventory.ini target -m ping
```

Скриншот проверки: [06_ansible_ping_target.png](screenshots/06_ansible_ping_target.png)

## Проверка Docker и Molecule

Для Molecule использовался Docker driver. Docker был проверен командами:

```bash
groups
docker --version
docker ps
```

Скриншот: [01_docker_check.png](screenshots/01_docker_check.png)

Для работы с Molecule было создано Python-окружение:

```bash
python3 -m venv ~/molecule-venv
source ~/molecule-venv/bin/activate
pip install ansible molecule molecule-plugins[docker] ansible-lint docker
```

Проверка установленных инструментов:

```bash
ansible --version
molecule --version
docker --version
```

Скриншот: [02_molecule_installed.png](screenshots/02_molecule_installed.png)

## Переменные

Создаваемые пользователи и их открытые ключи определены в `group_vars/all.yml`.

Пример:

```yaml
managed_users:
  - name: roleuser
    group: roleuser
    shell: /bin/bash
    public_key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL6ipUTCLrQ/Z7JOsxSuI9sEkBS+wY/biaBSOSVYNilF roleuser-key"
    opt_dir: /opt/roleuser_workdir
    sudo_nopasswd: true

ssh_password_authentication: "no"
ssh_kbd_interactive_authentication: "no"
ssh_restart_service: true
ssh_service_name: ssh
```

Скриншот переменных: [05_vars_users_keys.png](screenshots/05_vars_users_keys.png)

Для пользователя `roleuser` был создан SSH-ключ:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/roleuser_key -C "roleuser-key"
```

Скриншот: [04_roleuser_key_created.png](screenshots/04_roleuser_key_created.png)

Приватный ключ в репозиторий не добавлялся.

## Запуск playbook

Основной playbook подключает две роли:

```yaml
---
- name: Configure users and SSH on remote machine using roles
  hosts: target
  become: true

  roles:
    - user_management
    - ssh_hardening
```

Запуск выполнялся командой:

```bash
ansible-playbook -i inventory.ini playbook.yml -K
```

Ключ `-K` использовался для ввода sudo-пароля пользователя `user` на удалённой машине.

Скриншоты запуска:

- [07a_roles_playbook_run.png](screenshots/07a_roles_playbook_run.png)
- [07b_roles_playbook_recap.png](screenshots/07b_roles_playbook_recap.png)

На итоговом скриншоте видно, что playbook завершился без ошибок:

```text
failed=0
```

## Проверка результата

### 1. Пользователь создан

Проверка:

```bash
ansible -i inventory.ini target -m command -a "id roleuser" -b -K
```

Скриншот: [08_roleuser_created.png](screenshots/08_roleuser_created.png)

### 2. Sudo-права выданы

Проверка:

```bash
ansible -i inventory.ini target -m command -a "cat /etc/sudoers.d/roleuser" -b -K
```

Результат:

```text
roleuser ALL=(ALL) NOPASSWD:ALL
```

Скриншот: [09_roleuser_sudo_rights.png](screenshots/09_roleuser_sudo_rights.png)

### 3. SSH-вход по ключу работает

Проверка:

```bash
ssh -i ~/.ssh/roleuser_key roleuser@192.168.100.20
```

Скриншот подключения: [10a_roleuser_ssh_login.png](screenshots/10a_roleuser_ssh_login.png)

Внутри SSH-сессии были выполнены команды:

```bash
whoami
hostname
```

Результат подтвердил, что вход выполнен под пользователем `roleuser` на машине `ansible-target`.

Скриншот: [10b_roleuser_ssh_check.png](screenshots/10b_roleuser_ssh_check.png)

### 4. SSH-авторизация по паролю отключена

Проверка:

```bash
ansible -i inventory.ini target -m shell -a "sshd -T | grep -E 'passwordauthentication|kbdinteractiveauthentication'" -b -K
```

Результат:

```text
passwordauthentication no
kbdinteractiveauthentication no
```

Скриншот: [11_password_auth_disabled.png](screenshots/11_password_auth_disabled.png)

### 5. Директория в `/opt` создана

Проверка:

```bash
ansible -i inventory.ini target -m command -a "ls -ld /opt/roleuser_workdir" -b -K
```

Результат:

```text
drw-rw---- 2 roleuser roleuser ... /opt/roleuser_workdir
```

Это подтверждает, что директория создана в `/opt`, имеет права `660`, владельцем является `roleuser`, группой также является `roleuser`.

Скриншот: [12_roleuser_opt_directory.png](screenshots/12_roleuser_opt_directory.png)

## Molecule-тестирование

Для тестирования ролей был создан Molecule-сценарий:

```text
molecule/default/
├── Dockerfile.j2
├── molecule.yml
├── converge.yml
└── verify.yml
```

В `molecule.yml` используется Docker driver:

```yaml
driver:
  name: docker
```

Запуск тестирования:

```bash
molecule test
```

Скриншоты:

- [13a_molecule_test_run.png](screenshots/13a_molecule_test_run.png)
- [13b_molecule_test_success.png](screenshots/13b_molecule_test_success.png)

На итоговом скриншоте видно:

```text
verify: Executed: Successful
destroy: Executed: Successful
failed=0
```

Это подтверждает, что роли успешно протестированы через Molecule с Docker.

## Как работает роль `user_management`

Роль `user_management` выполняет пользовательскую часть задания:

- создаёт группы пользователей;
- создаёт пользователей;
- создаёт sudoers-файл для sudo без пароля;
- добавляет публичный SSH-ключ в `authorized_keys`;
- создаёт директорию в `/opt` с правами `660`.

Роль использует список пользователей из переменной `managed_users`.

## Как работает роль `ssh_hardening`

Роль `ssh_hardening` отвечает за настройки SSH:

- создаёт конфигурационный файл `/etc/ssh/sshd_config.d/00-disable-password-auth.conf`;
- задаёт `PasswordAuthentication no`;
- задаёт `KbdInteractiveAuthentication no`;
- дополнительно меняет эти параметры в основном `/etc/ssh/sshd_config`;
- перезапускает SSH-сервис через handler.

## Скриншоты

| № | Скриншот | Что подтверждает |
|---|---|---|
| 1 | [01_docker_check.png](screenshots/01_docker_check.png) | Docker установлен и доступен пользователю |
| 2 | [02_molecule_installed.png](screenshots/02_molecule_installed.png) | Установлены Ansible, Molecule и Docker plugin |
| 3 | [03_project_structure.png](screenshots/03_project_structure.png) | Создана структура с несколькими ролями |
| 4 | [04_roleuser_key_created.png](screenshots/04_roleuser_key_created.png) | Создан SSH-ключ для пользователя `roleuser` |
| 5 | [05_vars_users_keys.png](screenshots/05_vars_users_keys.png) | Пользователь и публичный ключ определены через vars |
| 6 | [06_ansible_ping_target.png](screenshots/06_ansible_ping_target.png) | Ansible подключается к удалённой машине |
| 7 | [07a_roles_playbook_run.png](screenshots/07a_roles_playbook_run.png) | Выполняются задачи роли `user_management` |
| 8 | [07b_roles_playbook_recap.png](screenshots/07b_roles_playbook_recap.png) | Playbook завершился без ошибок |
| 9 | [08_roleuser_created.png](screenshots/08_roleuser_created.png) | Пользователь `roleuser` создан |
| 10 | [09_roleuser_sudo_rights.png](screenshots/09_roleuser_sudo_rights.png) | Пользователю выданы sudo-права |
| 11 | [10a_roleuser_ssh_login.png](screenshots/10a_roleuser_ssh_login.png) | SSH-вход под пользователем `roleuser` работает |
| 12 | [10b_roleuser_ssh_check.png](screenshots/10b_roleuser_ssh_check.png) | Подключение выполнено к `ansible-target` под `roleuser` |
| 13 | [11_password_auth_disabled.png](screenshots/11_password_auth_disabled.png) | SSH-авторизация по паролю отключена |
| 14 | [12_roleuser_opt_directory.png](screenshots/12_roleuser_opt_directory.png) | Директория в `/opt` создана с правами `660` |
| 15 | [13a_molecule_test_run.png](screenshots/13a_molecule_test_run.png) | Запущено тестирование Molecule |
| 16 | [13b_molecule_test_success.png](screenshots/13b_molecule_test_success.png) | Molecule-тест завершился успешно |

## Вывод

В результате было выполнено домашнее задание по Ansible roles. Решение разделено на две роли: `user_management` и `ssh_hardening`. Пользователь `roleuser` и его публичный ключ определены через `vars`. Роли успешно применены к удалённой машине `ansible-target`, где был создан пользователь, настроены sudo-права, SSH-авторизация по ключу, отключена авторизация по паролю и создана директория в `/opt` с правами `660`. Дополнительно роли были протестированы через Molecule с использованием Docker driver.
