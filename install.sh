#!/bin/bash

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
SERVICEDIR="$CURRENT/Malachite.Service"

# Path to service executables
SERVICEBINDIR="$SERVICEDIR/bin"

# Project directory
PROJDIR="$CURRENT/$PROJECT"

# Service config
SERVICE_CONFIG=$SERVICE.service

# Service config path
SERVICE_CONFIG_PATH=$SERVICEDIR/$SERVICE_CONFIG

# Path to service
SERVICE_PATH=$SERVICEBINDIR/$PROJECT.dll

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

# Remove service directory if exist
rm -rf $SERVICEDIR

# Build and publish binaries
dotnet publish "$PROJDIR/$PROJECT.csproj" \
    -c $CONFIGURATION \
    -o $SERVICEBINDIR \
    --version-suffix $VERSION \
    --no-self-contained \
    --nologo

if [ "$(systemctl is-active --quiet $SERVICE)" ];
then
    echo "Detect $SERVICE is running. Stopping service..." >&2
    
    # Show status service
    systemctl stop $SERVICE     

    if [ $? -eq 1 ]; then
        # systemctl kill -s SIGKILL $SERVICE  
        exit 1
    fi
fi

if [ "$(systemctl | grep $SERVICE)" ];
then
    echo "Detect $SERVICE exist." >&2

    # disable service
    systemctl disable $SERVICE

    # remove $SERVICE config
fi

# Path to dotnet
DOTNETPATH=$(which dotnet)

# Create service config
touch $SERVICE_CONFIG_PATH

# Set permissions (-rw-rw-r--)
chmod 664 $SERVICE_CONFIG_PATH

# Write file content
cat > $SERVICE_CONFIG_PATH <<EOF
[Unit]
Description=Malachite link parser service

[Service]
WorkingDirectory=$SERVICEDIR
ExecStart=$DOTNETPATH $SERVICE_PATH
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=$SERVICE
User=$USER
Environment=ASPNETCORE_ENVIRONMENT=$ASPNETCORE_ENVIRONMENT
Environment= 

[Install]
WantedBy=multi-user.target
EOF

# Create symlink
ln -sf $SERVICE_CONFIG_PATH /etc/systemd/system/$SERVICE_CONFIG

# Reload
systemctl daemon-reload

# Start service
systemctl start $SERVICE

exit 0