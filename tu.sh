#!/bin/bash

# Function to display logo
logo() {
    clear
    echo " ++++++++++++++++++++++++++++++++++
 + cPanel License Manager +
 ++++++++++++++++++++++++++++++++++
"
    echo
}

# Function to add email address for self-registration
add_email() {
    logo
    read -r -p "A valid email address is required to use the free cPanel license.
Do you agree with this? [Y or n] " input
    case $input in
        [yY][eE][sS]|[yY])
            clear
            echo "
For activation, I need a valid email address.
Attention, confirmation is required!
"
            read -p 'Your Email Address: ' client_email
            echo "$client_email" | tee -a /root/.forward >/dev/null 1>&1
            ;;
        [nN][oO]|[nN])
            echo "Goodbye !!!"
            exit -1
            ;;
        *)
            echo "Invalid input...try again"
            exit 0
            ;;
    esac
}

# Function to update OS
update_os() {
    if [ ! -e "/opt/tactu/.system_update" ]; then 
        if [[ -f /etc/centos-release || -f /etc/almalinux-release || -f /etc/rocky-release ]]; then
            echo "Start updating server and installing apps. Please wait until completion..."
            echo "Installing epel-release / updating OS..."
            yum -y install epel-release >/dev/null 2>&1
            yum update -y >/dev/null 2>&1
            echo "Installing curl, bind-utils, openvpn..."
            yum install curl bind-utils openvpn -y >/dev/null 2>&1
        elif [[ -f /etc/lsb-release ]]; then
            echo "Start updating server and installing apps. Please wait until completion..."
            echo "Updating / upgrading OS..."
            apt update >/dev/null 2>&1
            apt upgrade -y >/dev/null 2>&1
            echo "Installing curl, dnsutils, openvpn..."
            apt install curl dnsutils openvpn -y >/dev/null 2>&1
        fi
        /usr/bin/touch /opt/tactu/.system_update
    fi
}

# Function to check and add email address
check_email_address() {
    update_os
    logo
    echo "Start Install License..."
    if [ ! -e "/opt/tactu/verificare" ]; then
        curl -s -A "cpanel" http://cpanel.network/verificare -o /opt/tactu/verificare
        chmod +x /opt/tactu/verificare
    fi
    # Verify email address
    email_register=$(cat /root/.forward)

    if [ -z "$email_register" ]; then
        add_email
        echo "After adding an email address, please run again: /opt/tactu_cpanel"
        exit
    fi

    if ! verificare_output=$(/opt/tactu/verificare "$email_register"); then
        echo "Status email address: [ERROR]"
        echo "
License data will be sent to this email address.
"
        exit
    fi

    echo "Status email address: [OK]"
}

# Function to update information
update_info() {
    :
}

# Function to update link
update_link() {
    :
}

# Function to register server
register_server() {
    :
}

# Function to update license
update_license() {
    :
}

# Main part of the script
if [ ! -d "/opt/tactu/" ]; then
    mkdir /opt/tactu/
fi

# Start of script execution
if [ $# -eq 0 ]; then
    logo
    echo "Usage:
/opt/tactu_cpanel activate | for activating or installing license
/opt/tactu_cpanel update   | for updating license
"
    exit 1
fi

case "$1" in
    update)
        update_info
        update_link

        # Check for stable version of the license script
        version_script_local=$(/usr/bin/syslic_cpanel script)
        version_script=$(curl -s -A "cpanel" http://cpanel.network/version_script)

        if [ "$version_script" != "$version_script_local" ]; then
            rm -f /usr/bin/syslic_cpanel
            curl -Ls -A "cpanel" http://cpanel.network/syslic_cpanel.x -o /usr/bin/syslic_cpanel
            chmod +x /usr/bin/syslic_cpanel
        else
            echo "You are using the latest version of the script" 
        fi

        # Check for stable version of cPanel
        version=$(/usr/bin/syslic_cpanel version)
        local_version=$(cat /usr/local/cpanel/version)

        if [ "$version" != "$local_version" ]; then
            echo "$version" > /usr/local/cpanel/version
            chattr -ia /etc/cpupdate.conf
            sed -i -r 's/CPANEL=(.+)/CPANEL=$version/g' /etc/cpupdate.conf
            /scripts/upcp --force
            sleep 5
        fi
        ;;
    activate)
        update_info
        update_link

        if [ ! -e "/opt/tactu/.serial" ]; then
            check_email_address
            if [ "$(register_server)" = "200" ]; then
                rm -f /opt/tactu/register_license_cpanel
                if [ ! -e "/etc/cron.d/tactu_cpanel" ]; then
                    now=$(date +'%M')
                    echo "
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
$now */6 * * * root /opt/tactu_cpanel update >/dev/null 2>&1
" | tee -a /etc/cron.d/tactu_cpanel >/dev/null 2>&1
                fi
                if [ ! -e "/usr/bin/syslic_cpanel" ]; then
                    curl -Ls -A "cpanel" http://cpanel.network/syslic_cpanel.x -o /usr/bin/syslic_cpanel
                    chmod +x /usr/bin/syslic_cpanel
                    /usr/bin/syslic_cpanel
                fi
            else
                echo "Error Register Server, license exist or your IP address is banned. Contact support for more info..."
                echo "IPv4: $(4_ip)"
                echo "IPv6: $(6_ip)"
            fi
        else
            update_license cpanel
        fi
        ;;
    *)
        logo
        echo "Invalid option. Please choose 'activate' or 'update'."
        exit 1
        ;;
esac
