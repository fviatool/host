#!/bin/bash

# Kiểm tra quyền root
if [ "$(id -u)" -ne 0 ]; then
    echo "Lỗi: Tập lệnh này chỉ có thể được thực thi bởi người dùng root hoặc với quyền sudo"
    exit 1
fi

# Cập nhật danh sách gói phần mềm
apt-get update 
apt install dovecot-imapd dovecot-pop3d -y
apt install zip -y

apt install wget git -y


# Cài đặt các gói phần mềm cần thiết
apt-get install nano wget perl -y

# Tải và chạy tập lệnh cài đặt DirectAdmin
wget https://raw.githubusercontent.com/LinuxGuard/Directadmin-1.60.4-Nulled/master/setup.sh
chmod +x setup.sh
./setup.sh

# Cấu hình firewall
firewall-cmd --zone=public --add-port=21/tcp --permanent
firewall-cmd --zone=public --add-port=22/tcp --permanent
firewall-cmd --zone=public --add-port=25/tcp --permanent
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=443/tcp --permanent
firewall-cmd --zone=public --add-port=465/tcp --permanent
firewall-cmd --zone=public --add-port=2222/tcp --permanent
firewall-cmd --reload

# Khởi động lại dịch vụ DirectAdmin
systemctl restart directadmin

# Đặt lại cấu hình và khởi động lại DirectAdmin
systemctl stop directadmin
rm -rf /usr/local/directadmin/conf/license.key
wget -O /usr/local/directadmin/conf/license.key https://raw.githubusercontent.com/LinuxGuard/Directadmin-1.60.4-Nulled/master/license.key
chmod 600 /usr/local/directadmin/conf/license.key
chown diradmin:diradmin /usr/local/directadmin/conf/license.key
systemctl restart network

# Cấu hình giao diện mạng và khởi động lại dịch vụ DirectAdmin
ifconfig eth0:92 37.97.247.189 netmask 255.255.255.0 up
echo 'DEVICE=eth0:92' >> /etc/sysconfig/network-scripts/ifcfg-eth0:92
echo 'IPADDR=37.97.247.189' >> /etc/sysconfig/network-scripts/ifcfg-eth0:92
echo 'NETMASK=255.255.255.0' >> /etc/sysconfig/network-scripts/ifcfg-eth0:92
systemctl restart network

# Cấu hình file cấu hình DirectAdmin
/usr/bin/perl -pi -e 's/^ethernet_dev=.*/ethernet_dev=eth0:92/' /usr/local/directadmin/conf/directadmin.conf

# Khởi động lại dịch vụ DirectAdmin
systemctl start directadmin

# Tạo một người dùng mới trong DirectAdmin
username="admin"
password="@Aa123123"
email="hbxomlieu@gmail.com"
echo "Creating new user: $username"
/usr/local/directadmin/scripts/create_new_user $username $password $email
echo "Đã tạo người dùng mới: $username"

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

wget -N http://files.softaculous.com/install.sh
chmod 755 install.sh
./install.sh

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
