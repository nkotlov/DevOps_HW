\# ДЗ 2. Ansible playbook



\## Цель задания



Необходимо написать Ansible playbook, который на удалённой машине выполняет настройку пользователя, sudo-прав, SSH-авторизации по ключам, отключение SSH-входа по паролю и создание директории в `/opt`.



По условию playbook должен:



\- создать пользователя на удалённой машине;

\- дать пользователю права `sudo`;

\- сделать авторизацию SSH по ключам для пользователя;

\- отключить авторизацию по паролю при SSH-подключении;

\- создать директорию в `/opt/` с правами `660` для пользователя.



\## Состав работы



| Файл / папка | Назначение |

|---|---|

| `ansible.cfg` | Базовая конфигурация Ansible |

| `inventory.ini` | Inventory-файл с удалённой машиной |

| `playbook.yml` | Основной Ansible playbook |

| `files/devopsuser\_key.pub` | Публичный SSH-ключ для нового пользователя |

| `screenshots/` | Скриншоты выполнения и проверки результата |



\## Используемый стенд



Работа выполнялась на двух виртуальных машинах Ubuntu:



| Машина | Назначение | IP |

|---|---|---|

| `Ubuntu-Control` | Управляющая машина с Ansible | `192.168.100.10` |

| `Ubuntu-Target` | Удалённая машина, на которую применялся playbook | `192.168.100.20` |



С управляющей машины `Ubuntu-Control` выполнялся запуск Ansible, а все изменения применялись на удалённой машине `Ubuntu-Target`.



\## Проверка сети между машинами



Перед запуском Ansible была проверена доступность удалённой машины по сети:



```bash

ping -c 4 192.168.100.20

```



Результат проверки сети:



\[01\_network\_ping\_control\_to\_target.png](screenshots/01\_network\_ping\_control\_to\_target.png)



\## Подготовка SSH-доступа для Ansible



Для подключения Ansible к удалённой машине был создан SSH-ключ:



```bash

ssh-keygen -t ed25519 -f \~/.ssh/ansible\_control\_key -C "ansible-control"

```



Проверка созданных ключей:



```bash

ls -l \~/.ssh/ansible\_control\_key\*

```



Скриншот:



\[02\_ansible\_control\_key.png](screenshots/02\_ansible\_control\_key.png)



После этого ключ был скопирован на удалённую машину, и был проверен SSH-вход:



```bash

ssh -i \~/.ssh/ansible\_control\_key user@192.168.100.20

```



Проверка подключения к удалённой машине:



\[03a\_ssh\_login\_to\_target.png](screenshots/03a\_ssh\_login\_to\_target.png)



Дополнительно внутри SSH-сессии были выполнены команды:



```bash

hostname

whoami

```



Результат показал, что подключение выполнено именно к удалённой машине `ansible-target` под пользователем `user`.



Скриншот:



\[03b\_ssh\_hostname\_whoami.png](screenshots/03b\_ssh\_hostname\_whoami.png)



\## Подготовка SSH-ключа для нового пользователя



Для нового пользователя `devopsuser` был создан отдельный SSH-ключ:



```bash

ssh-keygen -t ed25519 -f \~/.ssh/devopsuser\_key -C "devopsuser-key"

```



Публичный ключ был сохранён в файл:



```text

files/devopsuser\_key.pub

```



Проверка созданного ключа:



\[04\_devopsuser\_key\_created.png](screenshots/04\_devopsuser\_key\_created.png)



\## Inventory



В файле `inventory.ini` был описан удалённый узел:



```ini

\[target]

ansible-target ansible\_host=192.168.100.20 ansible\_user=user ansible\_ssh\_private\_key\_file=/home/user/.ssh/ansible\_control\_key

```



Проверка подключения Ansible к удалённой машине выполнялась командой:



```bash

ansible -i inventory.ini target -m ping

```



Результат проверки:



\[05\_ansible\_ping.png](screenshots/05\_ansible\_ping.png)



\## Запуск playbook



Playbook запускался с управляющей машины командой:



```bash

ansible-playbook -i inventory.ini playbook.yml -K

```



Ключ `-K` использовался для ввода пароля sudo пользователя `user` на удалённой машине.



Во время выполнения playbook были выполнены задачи:



\- создание группы для пользователя;

\- создание пользователя `devopsuser`;

\- выдача sudo-прав без пароля;

\- добавление SSH-ключа для пользователя;

\- отключение SSH-авторизации по паролю;

\- перезапуск SSH-сервиса;

\- создание директории в `/opt`.



Скриншоты запуска playbook:



\[06a\_playbook\_run\_tasks.png](screenshots/06a\_playbook\_run\_tasks.png)



\[06b\_playbook\_run\_recap.png](screenshots/06b\_playbook\_run\_recap.png)



На итоговом скриншоте видно, что playbook завершился без ошибок:



```text

failed=0

```



\## Проверка результата



\### 1. Проверка создания пользователя



Проверка выполнялась командой:



```bash

ansible -i inventory.ini target -m command -a "id devopsuser" -b -K

```



Результат показал, что пользователь `devopsuser` создан на удалённой машине.



Скриншот:



\[07\_user\_created.png](screenshots/07\_user\_created.png)



\### 2. Проверка sudo-прав пользователя



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



\[08\_sudo\_rights.png](screenshots/08\_sudo\_rights.png)



\### 3. Проверка SSH-авторизации по ключу



После выполнения playbook был проверен вход под новым пользователем по SSH-ключу:



```bash

ssh -i \~/.ssh/devopsuser\_key devopsuser@192.168.100.20

```



Скриншот подключения:



\[09a\_ssh\_key\_login\_devopsuser.png](screenshots/09a\_ssh\_key\_login\_devopsuser.png)



Внутри SSH-сессии были выполнены команды:



```bash

whoami

hostname

```



Результат показал:



```text

devopsuser

ansible-target

```



Скриншот проверки:



\[09b\_ssh\_key\_login\_devopsuser\_check.png](screenshots/09b\_ssh\_key\_login\_devopsuser\_check.png)



\### 4. Проверка отключения SSH-входа по паролю



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



\[10\_password\_auth\_disabled.png](screenshots/10\_password\_auth\_disabled.png)



\### 5. Проверка директории в `/opt`



Проверка директории выполнялась командой:



```bash

ansible -i inventory.ini target -m command -a "ls -ld /opt/devopsuser\_workdir" -b -K

```



Результат показал:



```text

drw-rw---- 2 devopsuser devopsuser ... /opt/devopsuser\_workdir

```



Это означает, что директория создана в `/opt`, имеет права `660`, владельцем является `devopsuser`, группой также является `devopsuser`.



Скриншот:



\[11\_opt\_directory\_permissions.png](screenshots/11\_opt\_directory\_permissions.png)



\## Как работает playbook



Playbook применяется к группе хостов `target`, описанной в файле `inventory.ini`. Подключение к удалённой машине выполняется по SSH с использованием ключа `ansible\_control\_key`.



Сначала playbook создаёт группу и пользователя `devopsuser` на удалённой машине. Затем для пользователя создаётся sudoers-файл `/etc/sudoers.d/devopsuser`, в котором задаётся правило выполнения sudo-команд без запроса пароля.



После этого playbook добавляет публичный SSH-ключ из файла `files/devopsuser\_key.pub` в `authorized\_keys` пользователя `devopsuser`. Это позволяет подключаться к удалённой машине под этим пользователем по SSH-ключу.



Для отключения SSH-авторизации по паролю playbook настраивает параметры `PasswordAuthentication no` и `KbdInteractiveAuthentication no`, после чего перезапускает SSH-сервис.



В конце playbook создаёт директорию `/opt/devopsuser\_workdir`, назначает владельцем и группой пользователя `devopsuser`, а также выставляет права `660`.



\## Скриншоты



| № | Скриншот | Что подтверждает |

|---|---|---|

| 1 | \[01\_network\_ping\_control\_to\_target.png](screenshots/01\_network\_ping\_control\_to\_target.png) | Удалённая машина доступна по сети |

| 2 | \[02\_ansible\_control\_key.png](screenshots/02\_ansible\_control\_key.png) | Создан SSH-ключ для подключения Ansible |

| 3 | \[03a\_ssh\_login\_to\_target.png](screenshots/03a\_ssh\_login\_to\_target.png) | SSH-подключение к удалённой машине работает |

| 4 | \[03b\_ssh\_hostname\_whoami.png](screenshots/03b\_ssh\_hostname\_whoami.png) | Подключение выполнено к `ansible-target` под пользователем `user` |

| 5 | \[04\_devopsuser\_key\_created.png](screenshots/04\_devopsuser\_key\_created.png) | Создан ключ для нового пользователя |

| 6 | \[05\_ansible\_ping.png](screenshots/05\_ansible\_ping.png) | Ansible успешно подключается к удалённой машине |

| 7 | \[06a\_playbook\_run\_tasks.png](screenshots/06a\_playbook\_run\_tasks.png) | Playbook выполняет задачи настройки |

| 8 | \[06b\_playbook\_run\_recap.png](screenshots/06b\_playbook\_run\_recap.png) | Playbook завершился без ошибок |

| 9 | \[07\_user\_created.png](screenshots/07\_user\_created.png) | Пользователь `devopsuser` создан |

| 10 | \[08\_sudo\_rights.png](screenshots/08\_sudo\_rights.png) | Пользователю выданы sudo-права без пароля |

| 11 | \[09a\_ssh\_key\_login\_devopsuser.png](screenshots/09a\_ssh\_key\_login\_devopsuser.png) | SSH-вход под новым пользователем по ключу работает |

| 12 | \[09b\_ssh\_key\_login\_devopsuser\_check.png](screenshots/09b\_ssh\_key\_login\_devopsuser\_check.png) | Подключение выполнено под пользователем `devopsuser` |

| 13 | \[10\_password\_auth\_disabled.png](screenshots/10\_password\_auth\_disabled.png) | SSH-авторизация по паролю отключена |

| 14 | \[11\_opt\_directory\_permissions.png](screenshots/11\_opt\_directory\_permissions.png) | Директория в `/opt` создана с правами `660` |



\## Вывод



В результате был написан Ansible playbook, который на удалённой машине создал пользователя `devopsuser`, выдал ему sudo-права без запроса пароля, настроил SSH-авторизацию по ключу, отключил SSH-вход по паролю и создал директорию `/opt/devopsuser\_workdir` с правами `660`.

