\# ДЗ 3. Ansible roles



\## Задание



Необходимо выполнить ту же постановку задачи, что и в задании с Ansible playbook, но с дополнительными требованиями:



\- реализовать решение как несколько Ansible roles;

\- задачи по пользователю вынести в отдельную роль;

\- настройки SSH вынести в отдельную роль;

\- создаваемые пользователи и их открытые ключи для авторизации должны быть определены через `vars`;

\- добавить тестирование ролей через Molecule;

\- для Molecule использовать Docker driver/provider.



\## Что реализовано



В работе реализованы две роли:



\- `user\_management` — создание пользователей, групп, sudo-прав, SSH-ключей и директорий в `/opt`;

\- `ssh\_hardening` — настройка SSH и отключение авторизации по паролю.



Пользователь `roleuser` и его публичный ключ определены в файле:



```text

group\_vars/all.yml

```



Для проверки ролей настроен Molecule-сценарий с Docker.



\## Файлы работы



\- `ansible.cfg` — базовая конфигурация Ansible;

\- `inventory.ini` — inventory-файл с удалённой машиной;

\- `playbook.yml` — основной playbook, который подключает роли;

\- `group\_vars/all.yml` — переменные с пользователями, ключами и SSH-настройками;

\- `roles/user\_management/` — роль для управления пользователями;

\- `roles/ssh\_hardening/` — роль для настройки SSH;

\- `molecule/default/` — Molecule-сценарий для тестирования ролей;

\- `screenshots/` — скриншоты выполнения и проверки результата.



\## Стенд



Работа выполнялась на двух виртуальных машинах Ubuntu:



\- `Ubuntu-Control` — управляющая машина, на которой установлен Ansible, Molecule и Docker;

\- `Ubuntu-Target` — удалённая машина, на которую применялись роли.



Используемые адреса:



\- `Ubuntu-Control`: `192.168.100.10`;

\- `Ubuntu-Target`: `192.168.100.20`.



\## Проверка Docker



Для Molecule использовался Docker driver. Перед запуском была проверена работа Docker:



```bash

groups

docker --version

docker ps

```



Скриншот:



\[01\_docker\_check.png](screenshots/01\_docker\_check.png)



На скриншоте видно, что пользователь входит в группу `docker`, Docker установлен и команда `docker ps` выполняется без ошибки доступа.



\## Установка Ansible и Molecule



Для работы с Molecule было создано Python-окружение:



```bash

python3 -m venv \~/molecule-venv

source \~/molecule-venv/bin/activate

```



Установка инструментов выполнялась командой:



```bash

pip install ansible molecule molecule-plugins\[docker] ansible-lint docker

```



Проверка версий:



```bash

ansible --version

molecule --version

docker --version

```



Скриншот:



\[02\_molecule\_installed.png](screenshots/02\_molecule\_installed.png)



\## Структура проекта



Структура проекта была создана вручную:



```bash

mkdir -p group\_vars

mkdir -p roles/user\_management/tasks

mkdir -p roles/ssh\_hardening/tasks

mkdir -p roles/ssh\_hardening/handlers

mkdir -p roles/ssh\_hardening/defaults

mkdir -p molecule/default

```



Проверка структуры:



```bash

tree .

```



Скриншот:



\[03\_project\_structure.png](screenshots/03\_project\_structure.png)



На скриншоте видно, что роли разделены на `user\_management` и `ssh\_hardening`.



\## Подготовка SSH-ключа для пользователя



Для пользователя `roleuser` был создан SSH-ключ:



```bash

ssh-keygen -t ed25519 -f \~/.ssh/roleuser\_key -C "roleuser-key"

```



Проверка созданного ключа:



```bash

ls -l \~/.ssh/roleuser\_key\*

cat \~/.ssh/roleuser\_key.pub

```



Скриншот:



\[04\_roleuser\_key\_created.png](screenshots/04\_roleuser\_key\_created.png)



Приватный ключ в репозиторий не добавляется. В переменные добавляется только публичный ключ.



\## Переменные



Пользователь и его открытый ключ определены через vars в файле:



```text

group\_vars/all.yml

```



Основная переменная:



```yaml

managed\_users:

&#x20; - name: roleuser

&#x20;   group: roleuser

&#x20;   shell: /bin/bash

&#x20;   public\_key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL6ipUTCLrQ/Z7JOsxSuI9sEkBS+wY/biaBSOSVYNilF roleuser-key"

&#x20;   opt\_dir: /opt/roleuser\_workdir

&#x20;   sudo\_nopasswd: true

```



Также в переменных заданы настройки SSH:



```yaml

ssh\_password\_authentication: "no"

ssh\_kbd\_interactive\_authentication: "no"

ssh\_restart\_service: true

ssh\_service\_name: ssh

```



Скриншот:



\[05\_vars\_users\_keys.png](screenshots/05\_vars\_users\_keys.png)



Этот пункт подтверждает, что создаваемые пользователи и их открытые ключи определены через `vars`.



\## Проверка подключения Ansible



Перед запуском ролей была проверена доступность удалённой машины через Ansible:



```bash

ansible -i inventory.ini target -m ping

```



Скриншот:



\[06\_ansible\_ping\_target.png](screenshots/06\_ansible\_ping\_target.png)



На скриншоте видно, что Ansible успешно подключается к `ansible-target`.



\## Запуск playbook с ролями



Основной playbook:



```yaml

\---

\- name: Configure users and SSH on remote machine using roles

&#x20; hosts: target

&#x20; become: true



&#x20; roles:

&#x20;   - user\_management

&#x20;   - ssh\_hardening

```



Запуск выполнялся командой:



```bash

ansible-playbook -i inventory.ini playbook.yml -K

```



Ключ `-K` использовался для ввода пароля sudo пользователя `user` на удалённой машине.



Скриншоты запуска:



\[07a\_roles\_playbook\_run.png](screenshots/07a\_roles\_playbook\_run.png)



\[07b\_roles\_playbook\_recap.png](screenshots/07b\_roles\_playbook\_recap.png)



На скриншотах видно, что выполняются задачи из ролей `user\_management` и `ssh\_hardening`, а итоговый результат содержит:



```text

failed=0

```



\## Проверка результата



\### 1. Проверка создания пользователя



Команда:



```bash

ansible -i inventory.ini target -m command -a "id roleuser" -b -K

```



Скриншот:



\[08\_roleuser\_created.png](screenshots/08\_roleuser\_created.png)



Результат подтверждает, что пользователь `roleuser` создан на удалённой машине.



\### 2. Проверка sudo-прав



Команда:



```bash

ansible -i inventory.ini target -m command -a "cat /etc/sudoers.d/roleuser" -b -K

```



Результат:



```text

roleuser ALL=(ALL) NOPASSWD:ALL

```



Скриншот:



\[09\_roleuser\_sudo\_rights.png](screenshots/09\_roleuser\_sudo\_rights.png)



Это подтверждает, что пользователю `roleuser` выданы права `sudo` без запроса пароля.



\### 3. Проверка SSH-входа по ключу



Команда:



```bash

ssh -i \~/.ssh/roleuser\_key roleuser@192.168.100.20

```



Скриншот подключения:



\[10a\_roleuser\_ssh\_login.png](screenshots/10a\_roleuser\_ssh\_login.png)



Внутри SSH-сессии были выполнены команды:



```bash

whoami

hostname

```



Скриншот:



\[10b\_roleuser\_ssh\_check.png](screenshots/10b\_roleuser\_ssh\_check.png)



Результат подтверждает, что вход выполнен под пользователем `roleuser` на машине `ansible-target`.



\### 4. Проверка отключения SSH-авторизации по паролю



Команда:



```bash

ansible -i inventory.ini target -m shell -a "sshd -T | grep -E 'passwordauthentication|kbdinteractiveauthentication'" -b -K

```



Результат:



```text

passwordauthentication no

kbdinteractiveauthentication no

```



Скриншот:



\[11\_password\_auth\_disabled.png](screenshots/11\_password\_auth\_disabled.png)



Это подтверждает, что авторизация по паролю при SSH-подключении отключена.



\### 5. Проверка директории в `/opt`



Команда:



```bash

ansible -i inventory.ini target -m command -a "ls -ld /opt/roleuser\_workdir" -b -K

```



Результат:



```text

drw-rw---- 2 roleuser roleuser ... /opt/roleuser\_workdir

```



Скриншот:



\[12\_roleuser\_opt\_directory.png](screenshots/12\_roleuser\_opt\_directory.png)



Это подтверждает, что директория создана в `/opt`, имеет права `660`, владельцем является `roleuser`, группой также является `roleuser`.



\## Тестирование через Molecule



Для тестирования ролей был настроен Molecule-сценарий:



```text

molecule/default/

├── Dockerfile.j2

├── molecule.yml

├── converge.yml

└── verify.yml

```



В файле `molecule.yml` используется Docker driver:



```yaml

driver:

&#x20; name: docker

```



Запуск тестирования:



```bash

molecule test

```



Скриншоты:



\[13a\_molecule\_test\_run.png](screenshots/13a\_molecule\_test\_run.png)



\[13b\_molecule\_test\_success.png](screenshots/13b\_molecule\_test\_success.png)



На итоговом скриншоте видно:



```text

verify: Executed: Successful

destroy: Executed: Successful

failed=0

```



Это подтверждает, что роли были протестированы через Molecule с Docker.



\## Как работает роль `user\_management`



Роль `user\_management` выполняет пользовательскую часть задания:



\- создаёт группы пользователей;

\- создаёт пользователей;

\- создаёт sudoers-файл для sudo без пароля;

\- добавляет публичный SSH-ключ в `authorized\_keys`;

\- создаёт директорию в `/opt` с правами `660`.



Роль использует список пользователей из переменной `managed\_users`.



\## Как работает роль `ssh\_hardening`



Роль `ssh\_hardening` отвечает за настройки SSH:



\- создаёт конфигурационный файл `/etc/ssh/sshd\_config.d/00-disable-password-auth.conf`;

\- задаёт `PasswordAuthentication no`;

\- задаёт `KbdInteractiveAuthentication no`;

\- дополнительно меняет эти параметры в основном `/etc/ssh/sshd\_config`;

\- перезапускает SSH-сервис через handler.



\## Скриншоты



| № | Скриншот | Что подтверждает |

|---|---|---|

| 1 | \[01\_docker\_check.png](screenshots/01\_docker\_check.png) | Docker установлен и доступен пользователю |

| 2 | \[02\_molecule\_installed.png](screenshots/02\_molecule\_installed.png) | Установлены Ansible, Molecule и Docker plugin |

| 3 | \[03\_project\_structure.png](screenshots/03\_project\_structure.png) | Создана структура с несколькими ролями |

| 4 | \[04\_roleuser\_key\_created.png](screenshots/04\_roleuser\_key\_created.png) | Создан SSH-ключ для пользователя `roleuser` |

| 5 | \[05\_vars\_users\_keys.png](screenshots/05\_vars\_users\_keys.png) | Пользователь и публичный ключ определены через vars |

| 6 | \[06\_ansible\_ping\_target.png](screenshots/06\_ansible\_ping\_target.png) | Ansible подключается к удалённой машине |

| 7 | \[07a\_roles\_playbook\_run.png](screenshots/07a\_roles\_playbook\_run.png) | Выполняются задачи роли `user\_management` |

| 8 | \[07b\_roles\_playbook\_recap.png](screenshots/07b\_roles\_playbook\_recap.png) | Playbook завершился без ошибок |

| 9 | \[08\_roleuser\_created.png](screenshots/08\_roleuser\_created.png) | Пользователь `roleuser` создан |

| 10 | \[09\_roleuser\_sudo\_rights.png](screenshots/09\_roleuser\_sudo\_rights.png) | Пользователю выданы sudo-права |

| 11 | \[10a\_roleuser\_ssh\_login.png](screenshots/10a\_roleuser\_ssh\_login.png) | SSH-вход под пользователем `roleuser` работает |

| 12 | \[10b\_roleuser\_ssh\_check.png](screenshots/10b\_roleuser\_ssh\_check.png) | Подключение выполнено к `ansible-target` под `roleuser` |

| 13 | \[11\_password\_auth\_disabled.png](screenshots/11\_password\_auth\_disabled.png) | SSH-авторизация по паролю отключена |

| 14 | \[12\_roleuser\_opt\_directory.png](screenshots/12\_roleuser\_opt\_directory.png) | Директория в `/opt` создана с правами `660` |

| 15 | \[13a\_molecule\_test\_run.png](screenshots/13a\_molecule\_test\_run.png) | Запущено тестирование Molecule |

| 16 | \[13b\_molecule\_test\_success.png](screenshots/13b\_molecule\_test\_success.png) | Molecule-тест завершился успешно |



\## Вывод



В результате было выполнено домашнее задание по Ansible roles. Решение разделено на две роли: `user\_management` и `ssh\_hardening`. Пользователь `roleuser` и его публичный ключ определены через `vars`. Роли успешно применены к удалённой машине `ansible-target`, где был создан пользователь, настроены sudo-права, SSH-авторизация по ключу, отключена авторизация по паролю и создана директория в `/opt` с правами `660`. Дополнительно роли были протестированы через Molecule с использованием Docker driver.

