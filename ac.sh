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

echo "Activation & Arming Completed"
