#!/bin/sh
if [ $(id -u) != "0" ]; then
    echo "Error: You have to login by user root!"
    exit
fi
if [ -f /var/cpanel/cpanel.config ]; then
    clear
    echo "Your Server installed WHM/Cpanel, if you want to use  DLEMP"
    echo "Lets rebuild VPS, you should use centos 6 or 7 - 64 bit"
    echo "Bye !"
    exit
fi

if [ -f /etc/psa/.psa.shadow ]; then
    clear
    echo "Server installed Plesk, if you want to use DLEMP"
    echo "Lets rebuild VPS, you should use centos 6 or 7 - 64 bit"
    echo "Bye !"
    exit
fi

if [ -f /etc/init.d/directadmin ]; then
    clear
    echo "Your Server installed DirectAdmin, if you want to use DLEMP"
    echo "Lets rebuild VPS, you should use centos 6 or 7 - 64 bit"
    echo "Bye !"
    exit
fi

if [ -f /etc/init.d/webmin ]; then
    clear
    echo "Your Server installed webmin, if you want to use DLEMP"
    echo "Lets rebuild VPS, you should use centos 6 or 7 - 64 bit"
    echo "Bye !"
    exit
fi

if [ ! -f /home/dlemp.conf ]; then
    #yum -y update
    yum -y install epel-release
    if [ -f /etc/yum.repos.d/epel.repo ]; then
        sudo sed -i "s/mirrorlist=https/mirrorlist=http/" /etc/yum.repos.d/epel.repo
    fi
    #yum -y update
    yum -y install psmisc bc gawk gcc wget unzip net-tools
    yum -y -q install virt-what sudo zip iproute iproute2 curl deltarpm yum-utils tar nano
    wget -q http://script.dlemp.net/calc -O /bin/calc && chmod +x /bin/calc
    if [ ! -f /bin/calc ]; then
        curl -o /bin/calc http://script.dlemp.net/calc
        chmod +x /bin/calc
    fi
    if [ ! -d /etc/dlemp ]; then
        mkdir -p /etc/dlemp
        mkdir -p /etc/dlemp/.tmp
    fi

    curl -L -k http://script.dlemp.net/dlemp-install-glibc -o dlemp-install-glibc && sh dlemp-install-glibc

    rm -rf /root/dlemp*
    rm -rf /etc/dlemp/.tmp/dlemp-setup*
fi
clear
echo "========================================================================="
echo "CHOOSE SETUP DLEMP NOW OR CHECK THIS VPS."
echo "-------------------------------------------------------------------------"
echo "Check VPS function: DLEMP will check: VPS info (location, server type,"
echo "-------------------------------------------------------------------------"
echo "CPU type, RAM, HDD speed...), SpeedTest ..."
echo "-------------------------------------------------------------------------"
echo "You also can use this check VPS function after setup DLEMP."
echo "========================================================================="
prompt="Type in your choice: "
options=("Setup DLEMP Now" "Check This VPS")
PS3="$prompt"
select opt in "${options[@]}"; do

    case "$REPLY" in
    1)
        luachon="caidatdlemp"
        break
        ;;
    2)
        luachon="check"
        break
        ;;
    0)
        luachon="thoat"
        break
        ;;
    *)
        echo "You typed wrong, Please type in the ordinal number on the list"
        continue
        ;;
    esac
done
if [ "$luachon" = "caidatdlemp" ]; then
    echo "========================================================================="
    echo "OK, Please wait ...."

    wget -q http://script.dlemp.net/setup/centos -O /etc/dlemp/.tmp/dlemp-setup

    chmod +x /etc/dlemp/.tmp/dlemp-setup
    clear
    #bash /etc/dlemp/.tmp/dlemp-setup
    /etc/dlemp/.tmp/dlemp-setup
elif [ "$luachon" = "check" ]; then
    echo "========================================================================="
    echo "OK, Please wait ...."
    sleep 3
    wget -q http://script.dlemp.net/checkvps.count -O /etc/dlemp/.tmp/axliasod
    rm -rf /etc/dlemp/.tmp/axliasod
    clear
    wget -q http://script.dlemp.net/kiem-tra-test-vps -O testvps && sh testvps
else
    clear
    wget -q http://script.dlemp.net/dlemp-en -O dlemp && sh dlemp
fi
