#!/bin/bash

### Global Variables
OS=$(uname -s)
DISTRIB=$(awk -F= '/^ID=/{print tolower($2)}' /etc/*release*)
SQUID_VERSION=4.8
CONFIG_FILE="config.cfg"
BASEDIR="/opt/squid"
PRIMARYKEY=18000

# Function to check if script is run as root
checkRoot() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "This script must be run as root" >&2
        exit 1
    else
        echo "User: root"
    fi
}

# Function to check if OS is Ubuntu
checkOS() {
    if [ "$OS" != "Linux" ] || [ "$DISTRIB" != "ubuntu" ]; then
        echo "Please run this script on Ubuntu Linux" >&2
        exit 1
    else
        echo "Operating System: $DISTRIB $OS"
    fi
}

# Function to get network interface
getInterface() {
    echo "Available Interfaces:"
    ls /sys/class/net/ | grep -v lo | awk '{print NR".",$1}'
    read -p "Enter the INTERFACE to be used: " INTERFACE
    echo "Setting INTERFACE: $INTERFACE"
    echo "INTERFACE=$INTERFACE" >> "$BASEDIR/$CONFIG_FILE"
}

# Function to install Squid
installSquid() {
    apt-get update -y
    apt-get install -y squid apache2 apache2-utils
    systemctl enable squid
    systemctl start squid
}

# Function to initialize files and directories
initializeFiles() {
    mkdir -p "$BASEDIR"
    cp proxy.sh monitor.sh initdb.sql "$BASEDIR/"
    echo "OS=$OS" >> "$BASEDIR/$CONFIG_FILE"
    echo "DISTRIBUTION=$DISTRIB" >> "$BASEDIR/$CONFIG_FILE"
    echo "BASEDIR=$BASEDIR" >> "$BASEDIR/$CONFIG_FILE"
    echo "PRIMARYKEY=$PRIMARYKEY" >> "$BASEDIR/$CONFIG_FILE"
    chmod +x "$BASEDIR/proxy.sh"
    touch /etc/squid/squiddb
    touch /etc/squid/squid.passwd
    mkdir -p /etc/squid/conf.d/
    touch /etc/squid/conf.d/sample.conf
}

# Function to install MariaDB
installMariadb() {
    apt-get install -y mariadb-server
    systemctl enable mysql
    systemctl start mysql
    mysql_secure_installation
}

# Function to initialize the database
initializeDB() {
    echo "Initializing Database structure. Please enter Password as root@2019 when prompted"
    cat initdb.sql | mysql -u root -p
}

# Function to set Squid configuration
setconfig() {
    cp /etc/squid/squid.conf /etc/squid/squid.conf.orig
    cat <<EOF > /etc/squid/squid.conf
# Squid Configuration
http_port 7656
visible_hostname localhost
# Add more configurations here...
EOF
}

# Main Function
main() {
    checkRoot
    checkOS
    getInterface
    installSquid
    initializeFiles
    installMariadb
    initializeDB
    setconfig
    ln -s "$BASEDIR/proxy.sh" /usr/bin/proxy
    touch /etc/squid/blacklist.acl
}

# Execute Main Function
main
