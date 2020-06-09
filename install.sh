#!/bin/bash

#
# Значения по-умолчанию
#

ENVIRONMENTS=(Development Production Debug)

DEFAULT_URL='http://*:5050'
DEFAULT_SERVICE='malachite-parser'
DEFAULT_VERSION='1.0'
DEFAULT_ENVIRONMENT=${ENVIRONMENTS[1]}


#
# Конфигурируемые параметры из аргументов командной строки
#

# URL сервиса включая протокол, хост и порт.
URL=$DEFAULT_URL               

# Версия сервиса для параметра --version-suffix
# Применяется при публикации приложения (dotnet publish)
VERSION=$DEFAULT_VERSION                  

# Имя сервиса для systemd
SERVICE=$DEFAULT_SERVICE                  

# Окружение в котором запускается приложение
ASPNETCORE_ENVIRONMENT=$DEFAULT_ENVIRONMENT 


#
# .NET and Project settings
#

# Проверяемая зависимость
ASPNETCOREAPP="Microsoft.AspNetCore.App 3.1" 

# Путь к dotnet. Вычисляется в dotnet_checks
DOTNETPATH=''                     

# Наименование проекта сервиса
PROJECT='Malachite.Parser.WebApi'   

# Директория проекта
PROJDIR="$PWD/$PROJECT"         

# Билд-конфигруация для сервиса (Release | Debug)
CONFIGURATION='Release'                   


#
# Параметры сервиса
#

# Директория для исполняемых файлов сервиса
SERVICEDIR="/var/www/${SERVICE}"          

# Путь к systemd-конфигруационному файлу
SERVICECONFIGPATH="/usr/lib/systemd/user/${SERVICE}.service" 

# Путь к библиотеке сервиса
SERVICEDLLPATH=$SERVICEDIR/$PROJECT.dll   

# Домашняя директория пользователя под которым запускается сервис.
# Она же является DOTNET_CLI_HOM. Вычисляется в create_service_user
SERVICEUSERHOME=''                        

# Пользователь под которым будет запущен сервис
# Если пользователя не существует то он будет создан
SERVICEUSER='malachite'            

# Группа под которой будет запущен сервис
# Если группый не существует то она будет создана
SERVICEGROUP='malachite'                  

# Телеметрия
DOTNET_PRINT_TELEMETRY_MESSAGE='True'     

# Признак деинсталляции
ISUNINSTALL=false                         


#
# Справка
#

usage() 
{
  cat - >&2 <<EOF
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
        По-умолчанию: ${DEFAULT_URL}

  -s, --service <arg>        
        Имя сервиса для systemctl
        По-умолчанию: ${DEFAULT_SERVICE}
  
  -e, --env <arg>        
        Рабочее окружение. Устанавливает значение для ASPNETCORE_ENVIRONMENT
        Выбор: ${ENVIRONMENTS[*]}
        По-умолчанию: ${DEFAULT_ENVIRONMENT}

  -v, --version <arg>        
        Версия сервиса
        По-умолчанию: ${DEFAULT_VERSION}  

  --uninstall        
        Удаляет демон и приложение 

EOF
}


#
# Показывает опции инсталляции 
#

print_install_options()
{
    cat - >&2 <<EOF

    Установка сервиса парсинга цен

    URL = ${URL}
    
    SERVICE           = ${SERVICE}
    SERVICEDIR        = ${SERVICEDIR}
    SERVICECONFIGPATH = ${SERVICECONFIGPATH}

    VERSION           = ${VERSION}
    ENVIRONMENT       = ${ASPNETCORE_ENVIRONMENT}

EOF
}


#
# Авариайное завершение с сообщением
#

fatal() 
{
    for i; do
        echo -e "\033[0;31mFatal: ${i}\033[0m" >&2
    done
    exit 1
}


#
# Штатное завершение с сообщением
#

success()
{
    for i; do
        echo -e "\033[32m${i}\033[0m" >&2
    done
    exit 0
}


#
# Разбор аргументов командной строки
#

parse_command_line_arg()
{    
    while [[ $# -gt 0 ]]
    do
        key="$1"  

        case $key in
            -u|--url)
                URL="$2"
                shift
                shift
            ;;
            -s|--service)
                SERVICE="$2"
                shift
                shift
            ;;
            -v|--version)
                VERSION="$2"
                shift
                shift 
            ;;
            -e|--env)

                if [[ ! " ${ENVIRONMENTS[@]} " =~ " $2 " ]]; 
                then
                    fatal "Неправильный аргумент --env ${2}, допустимые параметры: ${ENVIRONMENTS[*]}"
                fi

                ASPNETCORE_ENVIRONMENT="$2"
                shift
                shift 
            ;;
            --uninstall)
                ISUNINSTALL=true
                shift
            ;;
            -h|--help|*)
                usage
                return 1;
            ;;
        esac
    done

    return 0;
}


#
# Останавливает сервис $SERVICE 
#

stop_service() 
{
    systemctl stop $SERVICE 

    if [ $? -eq 1 ]; 
    then
        fatal "Service $SERVICE stopped failed"
    else
        echo -e "\033[32mService $SERVICE stopped\033[0m" >&2  
    fi
}


#
# Проверяет установку .NET Core
# 

dotnet_checks()
{
    if ! [ -x "$(command -v dotnet)" ]; 
    then
        fatal 'dotnet is not installed.'
    fi

    if ! [ "$(dotnet --list-runtimes | grep "$ASPNETCOREAPP")" ];
    then
        fatal "${ASPNETCOREAPP} is not installed."
    fi

    DOTNETPATH=$(which dotnet)
}


#
# Создает пользователя и группу для сервиса
#

create_service_user()
{
    # Create user group if not exist
    getent group $SERVICEGROUP || groupadd $SERVICEGROUP

    # Create user if not exist
    if ! [[ -n $(id -u $SERVICEUSER 2>/dev/null) ]];
    then
        echo "User $SERVICEUSER does not exist" >&2
        echo "Create user $SERVICEUSER:$SERVICEGROUP" >&2

        # Create user
        useradd -g $SERVICEGROUP $SERVICEUSER 

        # Add user to group $SERVICEGROUP
        # usermod -a -G $SERVICEGROUP $SERVICEUSER
    fi

    SERVICEUSERHOME=$(eval echo ~$SERVICEUSER)
}


#
# Билд и публикация сервиса в $SERVICEDIR
#

install_service() 
{
    # Remove service directory if exist
    rm -rf $SERVICEDIR

    # Build and publish binaries
    dotnet publish "$PROJDIR/$PROJECT.csproj" \
        -c $CONFIGURATION \
        -o $SERVICEDIR \
        --version-suffix $VERSION \
        --no-self-contained \
        --nologo

    # Change owner to $SERVICEUSER
    chown -R $SERVICEUSER:$SERVICEGROUP $SERVICEDIR/*
}


#
# Uninstall
#

uninstall()
{
    stop_service

    # Enabled
    systemctl disable $SERVICE

    # Reload
    systemctl daemon-reload

    # Remove service directory and service config
    rm -rf $SERVICEDIR
    rm -f $SERVICECONFIGPATH

    return 0;
}


#
# Создает конфиграцию сервиса в $SERVICECONFIGPATH
#

create_service_config()
{
    # Create service config
    touch $SERVICECONFIGPATH

    # Set permissions (-rw-rw-r--)
    chmod 664 $SERVICECONFIGPATH

    # Write file content
    cat > $SERVICECONFIGPATH <<EOF
[Unit]
Description=Malachite link parser service

[Service]
Type=simple
User=${SERVICEUSER}
Group=${SERVICEGROUP}
WorkingDirectory=${SERVICEDIR}
ExecStart=${DOTNETPATH} ${SERVICEDLLPATH} --urls ${URL}
StandardOutput=journal
KillMode=process
SyslogIdentifier=${SERVICE}
Environment=ASPNETCORE_ENVIRONMENT=${ASPNETCORE_ENVIRONMENT}
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=${DOTNET_PRINT_TELEMETRY_MESSAGE}
Environment=DOTNET_CLI_HOME=${SERVICEUSERHOME}

[Install]
WantedBy=multi-user.target
EOF
}


#
# Запускает сервис
#

run_service()
{
    # Enabled
    systemctl enable $SERVICECONFIGPATH

    # Reload
    systemctl daemon-reload

    # Start service
    systemctl start  $SERVICE
    systemctl status $SERVICE
}


# root

{
    parse_command_line_arg "$@" || exit 0

    if [ "$ISUNINSTALL" = true ];
    then
        uninstall && success 'Приложение успешно удалено'
    fi

    print_install_options

    if [ "$(whoami)" != 'root' ]; 
    then
        fatal "You have no permission to run $0 as non-root user."
    fi

    dotnet_checks

    if systemctl is-active --quiet $SERVICE ;
    then
        echo "Detect $SERVICE is running. Stopping service..." >&2
        stop_service
    fi

    create_service_user
    create_service_config

    install_service  
    run_service  
}