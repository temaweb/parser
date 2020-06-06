#!/bin/bash

# Host
URL='http://localhost:5050'

# Build Proj
PROJECT='Malachite.Parser.WebApi'

# Build configuration
CONFIGURATION='Release' # Debug | Release

# Application version
VERSION='1.0'

# ASP NET Core App version requred
ASPNETCOREAPP="Microsoft.AspNetCore.App 3.1"

# Environment
ASPNETCORE_ENVIRONMENT='Production' 

# Service name
SERVICE='malachite-parser'

# Current directory
CURRENT=$PWD # "$(dirname "$0")"

# Path to service directory 
SERVICEDIR="/var/www/$SERVICE"

# Project directory
PROJDIR="$CURRENT/$PROJECT"

# Service config path
SERVICECONFIGPATH=/usr/lib/systemd/user/$SERVICE.service

# Path to service library
SERVICEDLLPATH=$SERVICEDIR/$PROJECT.dll

# User
SERVICEUSER='malachite'

# Group
SERVICEGROUP='malachite'

if [ "$(whoami)" != 'root' ]; 
then
    echo "You have no permission to run $0 as non-root user."
    exit 1;
fi

if ! [ -x "$(command -v dotnet)" ]; 
then
    echo 'Error: dotnet is not installed.' >&2
    exit 1
fi

if ! [ "$(dotnet --list-runtimes | grep "$ASPNETCOREAPP")" ];
then
    echo "Error: $ASPNETCOREAPP is not installed." >&2
    exit 1
fi

if systemctl is-active --quiet $SERVICE ;
then
    echo "Detect $SERVICE is running. Stopping service..." >&2

    # Stop $SERVICE 
    systemctl stop $SERVICE 

    if [ $? -eq 1 ]; 
    then
        echo "Service $SERVICE stopped failed" >&2
        exit 1
    else
        echo "Service $SERVICE stopped" >&2  
    fi
fi

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

# $SERVICEUSER home directory
SERVICEUSERHOME=$(eval echo ~$SERVICEUSER)

# Path to dotnet
DOTNETPATH=$(which dotnet)

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
User=$SERVICEUSE
Group=$SERVICEGROUP
WorkingDirectory=$SERVICEDIR
ExecStart=$DOTNETPATH $SERVICEDLLPATH --urls $URL
StandardOutput=journal
KillMode=process
SyslogIdentifier=$SERVICE
Environment=ASPNETCORE_ENVIRONMENT=$ASPNETCORE_ENVIRONMENT
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=true
Environment=DOTNET_CLI_HOME=$SERVICEUSERHOME

[Install]
WantedBy=multi-user.target
EOF

# Enbled
systemctl enable $SERVICECONFIGPATH

# Reload
systemctl daemon-reload

# Start service
systemctl start  $SERVICE
systemctl status $SERVICE