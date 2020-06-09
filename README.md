# Малахит
*Сервис парсинга цен*

Демон работает по HTTP, получая ссылку на страницу с ценой и возвращая нормализованую строку с ценой.

### Справка

Запустите `install.sh` с ключем `-h|--help` для получения справки о работе инсталлятора

```
$ ./install.sh --help

NAME
    install.sh - Сценарий установки сервиса парсинга цен.

SYNOPSIS
    install.sh [-h|--help]
    install.sh [-u|--url <arg>]
               [-s|--service <arg>]
               [-v|--version <arg>]
               [-e|--env <arg>]
               [--uninstall]

OPTIONS
  -h, --help        
        Показывает справку

  -u, --url <arg>        
        Определяет URL сервиса включая протокол, хост и порт.
        По-умолчанию: http://*:5050

  -s, --service <arg>        
        Имя сервиса для systemctl
        По-умолчанию: malachite-parser
  
  -e, --env <arg>        
        Рабочее окружение. Устанавливает значение для ASPNETCORE_ENVIRONMENT
        Выбор: Development Production Debug
        По-умолчанию: Production

  -v, --version <arg>        
        Версия сервиса
        По-умолчанию: 1.0  

  --uninstall        
        Удаляет демон и приложение 
```

### Инсталляция

Для инсталляции клонируйте этот репозиторий и запустите install.sh под суперпользователем
```sh
$ git clone http://gitlab.lifeit.com/LifeIT/Malakhit/parser.git
$ cd parser
$ sudo ./install.sh
```

После успешной инсталляции будет создан пользователь malachite:malachite и запущен демон под этим пользователем  

```
● malachite-parser.service - Malachite link parser service
   Loaded: loaded (/usr/lib/systemd/user/malachite-parser.service; enabled; vendor preset: disabled)
   Active: active (running) since Sun 2020-06-07 13:55:43 MSK; 9ms ago
 Main PID: 128284 (dotnet)
    Tasks: 1 (limit: 100028)
   Memory: 756.0K
   CGroup: /system.slice/malachite-parser.service
           └─128284 /bin/dotnet /var/www/malachite-parser/Malachite.Parser.WebApi.dll --urls http://*:5050
```

### Удаление

Для удаление запустите скрипт с ключем `--uninstall`

```sh
$ sudo ./install.sh --uninstall
```

### Конфигурирация 

Параметры установки по-умолчанию:

```sh
URL = http://*:5050

# Имя сервиса для systemd
SERVICE = malachite-parser

# Директория для исполняемых файлов
SERVICEDIR = /var/www/malachite-parser

# Путь к конфигураицонному файлу демона
SERVICECONFIGPATH = /usr/lib/systemd/user/malachite-parser.service

# Версия приложения
VERSION = 1.0

# Рабочее окружение приложения
ENVIRONMENT = Production
```
