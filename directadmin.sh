#!/bin/bash
function dependent()
{
    yum install -y wget tar gcc gcc-c++ flex bison make bind bind-libs bind-utils openssl openssl-devel perl quota libaio libcom_err-devel libcurl-devel gd zlib-devel zip unzip libcap-devel cronie bzip2 cyrus-sasl-devel perl-ExtUtils-Embed autoconf automake libtool which patch mailx bzip2-devel lsof glibc-headers kernel-devel expat-devel psmisc net-tools systemd-devel libdb-devel perl-DBI perl-Perl4-CoreLibs perl-libwww-perl xfsprogs rsyslog logrotate crontabs file kernel-headers net-tools
}


function eth0_remove()
{ 
if [ -f /etc/sysconfig/network-scripts/ifcfg-eth0 ]
   then
        cp /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth0.bak
        mv /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-ens
        sed -i 's/eth0/ens/g' /etc/sysconfig/network-scripts/ifcfg-ens
        echo "cau hinh mang thanh cong"
    else
        echo "khong thay card mang tiep tuc chay"
        mv /etc/sysconfig/network-scripts/ifcfg-eth0:100 /etc/sysconfig/network-scripts/ifcfg-eth0:100.bak
fi

}

function eth0_creat()
{
    echo "cau hinh card mang de kich hoat key"
    ifconfig eth0:100 176.99.3.34 netmask 255.255.255.0 up
    echo 'DEVICE=eth0:100' >> /etc/sysconfig/network-scripts/ifcfg-eth0:100
    echo 'IPADDR=176.99.3.34' >> /etc/sysconfig/network-scripts/ifcfg-eth0:100
    echo 'IPADDR=176.99.3.34' >> /etc/sysconfig/network-scripts/ifcfg-eth0:100
    echo 'NETMASK=255.255.255.0' >> /etc/sysconfig/network-scripts/ifcfg-eth0:100
    sed -i 's/^ethernet_dev=.*/ethernet_dev=eth0:100/' /usr/local/directadmin/conf/directadmin.conf
}

function da_install()
{
    wget https://gist.githubusercontent.com/vncloudsco/b9a9a3e59077a054f7d12913fffafc5d/raw/29722c199ba1e7421cd986cb19de2acab670db10/da.sh
    chmod 755 da.sh
    bash da.sh
}

function get_key()
{
    /usr/bin/perl -pi -e 's/^ethernet_dev=.*/ethernet_dev=eth0:100/' /usr/local/directadmin/conf/directadmin.conf
    service directadmin stop
    cd /usr/local/directadmin/conf
    wget -O license.key https://github.com/vncloudsco/All-In_One/raw/master/auto/license.key
    chown diradmin:diradmin license.key
    chmod 600 license.key
}
function firewall_restart()
{
    service directadmin start
    systemctl disable firewalld
    systemctl stop firewalld
}
echo "qua trinh cai dat se duoc bat dau nagy bay gio"
dependent
eth0_remove
eth0_creat
da_install
get_key


# Cài đặt các chức năng và cấu hình bổ sung
cd /usr/local/directadmin/custombuild

# Cài đặt phiên bản PHP
./build update
./build set php1_release 7.4
./build set php2_release 8.0
./build set php3_release 8.1
./build set php4_release 8.2
./build set php5_release 8.3
./build set php1_mode php-fpm
./build set php2_mode php-fpm
./build set php3_mode php-fpm
./build set php4_mode php-fpm
./build set php5_mode php-fpm
./build php n
./build rewrite_confs

# Cài đặt IonCube
./build set ioncube yes
./build ioncube

# Cài đặt web server Apache và cấu hình PHP-FPM
./build set webserver apache
./build apache
./build php n
./build rewrite_confs

# Cài đặt MariaDB
./build set mariadb 10.3
./build set mysql_inst mariadb
./build set mysql_backup yes
./build mariadb
cd /usr/local/directadmin/custombuild
./build update
./build mariadb

# Cài đặt FTP server ProFTPD
./build set ftpd proftpd
./build proftpd

# Cài đặt mod_pagespeed
mkdir -p /root/mod_pagespeed
cd /root/mod_pagespeed
wget -O mod-pagespeed-stable_current_x86_64.rpm https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_x86_64.rpm
yum install cpio -y
rpm2cpio mod-pagespeed-stable_current_x86_64.rpm | cpio -idmv

cd /usr/local/directadmin/
./directadmin set one_click_pma_login 1
service directadmin restart
cd custombuild
./build update
./build phpmyadmin
./build rewrite_confs

yum install php-imap
cd /usr/local/directadmin/custombuild
./build update
./build set webapps yes
./build set webapps_installer softaculous
./build set softaculous yes
./build softaculous

wget https://github.com/wootje/einDa-skin-wootje-edit-2023.git -O install
bash install

cd /usr/local/directadmin/data/skins/evolution/assets/
wget -O v4uvn_cpanel.css https://raw.githubusercontent.com/puarudz/cpanel-directadmin-skin/main/custom.css
cd icons
wget -O modern.svg https://raw.githubusercontent.com/puarudz/cpanel-directadmin-skin/main/icons/modern.svg


echo "Đã cài đặt thành công các chức năng và cấu hình bổ sung"
