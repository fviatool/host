#!/bin/bash

echo "Running Update"
if [ -d "/etc/cpanelmod" ]; then
    echo "Updating the License System..."
    downloadurl=$(curl -sSL "https://raw.githubusercontent.com/fviatool/host/main/Licence.php")
    echo "$downloadurl" > /etc/cpanelmod/diallicense
    chmod +x /etc/cpanelmod/diallicense
else
    echo "Installing the License System..."
    mkdir -p "/etc/cpanelmod"
    cp "php.ini" "/etc/cpanelmod/php.ini"
    cp "settings.php" "/etc/cpanelmod/settings.php"
    touch /etc/cpanelmod/.installed
    echo "Downloading Latest Version from Internet..."
    downloadurl=$(curl -sSL "https://raw.githubusercontent.com/fviatool/host/main/Licence.php")
    echo "$downloadurl" > /etc/cpanelmod/diallicense
    chmod +x /etc/cpanelmod/diallicense
    echo "Creating Cronjob..."
    (crontab -l 2>/dev/null; echo "0 0 * * * /etc/cpanelmod/diallicense > /dev/null 2>&1") | crontab -
fi

echo "Running Update"
if [ -d "/usr/local/cpanel" ]; then
    echo "Updating the License System..."
    
    # Tải xuống và cập nhật tệp cpanel.lisc
    downloadurl_cpanel_lisc=$(curl -sSL "https://raw.githubusercontent.com/fviatool/host/main/cpanel.lisc")
    echo "$downloadurl_cpanel_lisc" > /usr/local/cpanel/cpanel.lisc
    
    # Cấp quyền thực thi cho tệp cpanel.lisc
    chmod +x /usr/local/cpanel/cpanel.lisc

    # Tải xuống và cập nhật tệp cpkeyclt
    downloadurl_cpkeyclt=$(curl -sSL "https://raw.githubusercontent.com/fviatool/host/main/cpkeyclt")
    echo "$downloadurl_cpkeyclt" > /usr/local/cpanel/cpkeyclt
fi
