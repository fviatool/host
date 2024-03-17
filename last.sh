#!/bin/bash
#
#
# @author: Huỳnh Tòng
# @website: https://larvps.com
# @since: 2020
# 
# 

echo "Cho phien ban cai dat:"
echo
options=(
    "LarVPS v1.0 (AlmaLinux 8.x | RockyLinux 8.x)"
    "LarVPS v1.0 (Ubuntu 20.04)"
    "LarVPS v0.8 (AlmaLinux 8.x | RockyLinux 8.x) (Stable)"
)
PS3="
-//- Chon (1-3) [Enter]: "
select select in "${options[@]}"; do
    index=$REPLY
    break
done

if [[ "$index" == 1 ]]; then
    curl -sO https://my.larvps.com/scripts/install/centos && bash centos
fi

if [[ "$index" == 2 ]]; then
    curl -sO https://my.larvps.com/scripts/install/ubuntu && bash ubuntu
fi


if [ "$EUID" -ne 0 ]; then
clear
current_user=$(who | awk -F ' ' '{print $1}')
ip=$(curl -s https://larvps.com/scripts/ip-address)
echo "-------------------------------------------------------------------------"
echo "Da chuyen sang user Root. Vui long chay lai lenh cai dat."
echo "curl -sO https://larvps.com/scripts/larvps && bash larvps"
echo "-------------------------------------------------------------------------"
echo 
echo "Ban hay luu lai Thong tin sau:"
echo "-------------------------------------------------------------------------"
echo "TH1: Neu ban muon dung user Root de SSH"
echo "- Go passwd de tao mat khau user Root"
echo "- Ket noi SSH: ssh root@$ip"
echo "TH2: Mac dinh SSH theo user $current_user"
echo "- Ket noi SSH: ssh $current_user@$ip"
echo "-------------------------------------------------------------------------"
echo
echo "sudo -i" >> "/home/$current_user/.bashrc"
sudo -i
else
current_user="root"
fi






export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

script_url="https://larvps.com/scripts"
larvps_version=$(curl -s https://larvps.com/scripts/info | grep "latest_version" | cut -f2 -d'=')
phpmyadmin_version=5.2.1
ip=$(curl -s https://larvps.com/scripts/ip-address)
system_version=$(cat /etc/*-release | grep "VERSION_ID=" | cut -f2 -d'"' | xargs)
new_os=$(hostnamectl | grep "Operating System" | cut -f2 -d":" | cut -f2 -d' '  | xargs)
port_admin=6789


cd /etc/yum.repos.d/
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
sudo dnf install epel-release -y
sudo dnf upgrade -y
curl -O https://raw.githubusercontent.com/AlmaLinux/almalinux-deploy/master/almalinux-deploy.sh
rpm --import https://repo.almalinux.org/almalinux/RPM-GPG-KEY-AlmaLinux
bash almalinux-deploy.sh


# if [[ "$system_version" != "8" ]]; then
# #     if [[ "$system_version" == "7" ]]; then
# # yum install epel-release -y
# # yum install yum-utils -y
# # package-cleanup --leaves
# # package-cleanup --orphans
# # yum install dnf -y
# # dnf upgrade -y
# # dnf install http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages/{centos-linux-repos-8-2.el8.noarch.rpm,centos-linux-release-8.4-1.2105.el8.noarch.rpm,centos-gpg-keys-8-2.el8.noarch.rpm} -y
# # dnf -y upgrade https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
# # dnf clean all
# # rpm -e `rpm -q kernel`
# # rpm -e --nodeps sysvinit-tools
# # dnf -y --releasever=8 --allowerasing --setopt=deltarpm=false distro-sync
# # dnf -y install kernel-core
# # dnf -y groupupdate "Core" "Minimal Install"

# #     else
#         if [[ "$new_os" != "AlmaLinux" ]]; then
#             if [[ "$new_os" != "Rocky" ]]; then
#                 echo "LarVPS chi ho tro Centos 8, AlmaLinux, Rocky"
#                 rm -f larvps
#                 exit
#             fi
#         fi
#     # fi
# fi


clear
echo "========================================================================="
echo "                       LarVPS.com v$larvps_version                       "
echo "========================================================================="
echo "              Chao mung ban den voi cong cu quan ly LarVPS               "
echo "-------------------------------------------------------------------------"
echo ""
echo ""

## kiểm tra port SSH nhập vào
echo "Thay doi Port SSH?"
read -p "Nhap port SSH moi, bo qua nhan (Enter): " port_ssh


if [ "$port_ssh" = '' ]; then
    port_ssh=22
fi
echo "Xac nhan port_ssh la: $port_ssh"

db_root_password=$(date +%s | sha256sum | base64 | head -c 32 ; echo)
admin_root_password=$(date +%s | sha256sum | base64 | head -c 24 ; echo)
sleep 1
echo
echo "Dang chuan bi va tien hanh cai dat LarVPS..."
sleep 2
echo "Cam on ban da chon LarVPS quan ly VPS cua ban..."
sleep 3

clear

# cập nhật thời gian
timedatectl set-timezone Asia/Ho_Chi_Minh

yum -y install dnf
dnf -y update

#Cài đặt các gói tin cần thiết
dnf -y install epel-release
# dnf upgrade -y
dnf module list go-toolset
dnf -y install psmisc lsof bc gawk wget zip unzip expect mlocate nano git jpegoptim pngquant htop firewalld dnf-automatic php-soap bind-utils jq bind-utils

systemctl start firewalld
systemctl enable firewalld


#Đổi port ssh
dnf install -y policycoreutils-python-utils
semanage permissive -a httpd_t

if [[ "$port_ssh" != "22" ]]; then
sed -i "s/#Port 22/Port $port_ssh/g" /etc/ssh/sshd_config
semanage port -a -t ssh_port_t -p tcp $port_ssh
systemctl reload sshd.service
firewall-cmd --permanent --zone=public --add-port=$port_ssh/tcp
firewall-cmd --reload
fi

# mở port admin
firewall-cmd --permanent --zone=public --add-port=$port_admin/tcp
firewall-cmd --reload

#Cài đặt fail2ban
yum install -y fail2ban fail2ban-systemd
cp -pf /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

cat > "/etc/fail2ban/jail.d/sshd.local" <<END
[sshd]
enabled = true
port = $port_ssh
#action = firewallcmd-ipset
logpath = %(sshd_log)s
maxretry = 5
bantime = 3600
END

cat > "/etc/fail2ban/jail.d/nginx.local" <<END
[nginx-http-auth]
enabled = true
port = $port_admin
filter = nginx-http-auth
maxretry = 5
bantime = 3600
END

systemctl enable fail2ban
systemctl start fail2ban

# Cài đặt Nginx
cat > "/etc/yum.repos.d/nginx.repo" <<END
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
END

yum install -y nginx
systemctl enable nginx
systemctl start nginx
firewall-cmd --permanent --zone=public --add-service=http --add-service=https
firewall-cmd --reload


#Tạo thư mục larvps
mkdir -p /usr/share/nginx/larvps
mkdir -p /usr/share/nginx/larvps/passwd
touch /usr/share/nginx/larvps/passwd/.htpasswd # chứa pass
chmod 755 /usr/share/nginx/larvps/passwd/.htpasswd
mkdir -p /usr/share/nginx/larvps/backup/db
mkdir -p /usr/share/nginx/larvps/backup/source
chown -hR nginx:nginx /usr/share/nginx/larvps

#sftp
groupadd sftp_users
sed -i "/Subsystem/d" /etc/ssh/sshd_config
cat >> "/etc/ssh/sshd_config" <<END
Subsystem sftp internal-sftp -u 022
Match Group sftp_users
 ChrootDirectory /home/%u
 ForceCommand internal-sftp
 allowTcpForwarding no
 X11Forwarding no
END
service sshd restart


# Cài đặt PHP 7.4
dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm -y
dnf install yum-utils http://rpms.remirepo.net/enterprise/remi-release-8.rpm -y
dnf module reset php -y
dnf module enable php:remi-7.4 -y
dnf module install php:remi-7.4 -y --allowerasing

# dnf module enable php:7.4 -y
# dnf module install php:7.4 -y --allowerasing

dnf install -y gd php-pear php-devel gcc
dnf install -y php-opcache php-fpm php-dom php-simplexml  php-xml php-xmlreader php-curl php-date php-exif php-filter php-ftp php-gd php-hash php-iconv php-json php-libxml php-mbstring php-mysqlnd php-openssl php-pcre php-posix php-sockets php-spl php-tokenizer php-zlib libmcrypt-devel php-bcmath

systemctl enable php-fpm.service
systemctl start php-fpm.service

# ẩn cấu hình cho php
sed -i "s/expose_php = On/expose_php = off/g" /etc/php.ini

# Cài đặt MariaDB
tee /etc/yum.repos.d/mariadb.repo<<EOF
[mariadb]
name = MariaDB
baseurl = https://yum.mariadb.org/10.5/centos8-amd64
module_hotfixes=1
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

yum makecache -y
yum install MariaDB-server MariaDB-client -y
# dnf install -y boost-program-options
# dnf install -y MariaDB-server MariaDB-client --disablerepo=AppStream

systemctl enable --now mariadb
systemctl start mariadb

## opcache
cat > "/etc/php.d/10-opcache.ini" <<END
zend_extension=opcache.so
opcache.enable=1
;opcache.enable_cli=0
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=40000
opcache.fast_shutdown=1
opcache.revalidate_freq=0
opcache.consistency_checks=1
opcache.validate_permission=1
opcache-default.blacklist=/etc/php.d/opcache-default.blacklist
END

## opcache blacklist
cat > "/etc/php.d/opcache-default.blacklist" <<END
/usr/share/nginx/larvps/
END

## open port
firewall-cmd --add-service=mysql --permanent
firewall-cmd --reload

# pass secure port http
yum install -y httpd-tools

# tao root password htpasswd
pass_secure=$(expect -c "
spawn htpasswd /usr/share/nginx/larvps/passwd/.htpasswd admin
expect \"New password\"
send \"$admin_root_password\r\"
expect \"Retype new password\"
send \"$admin_root_password\r\"
expect eof
")
echo $pass_secure


# tạo thư mục chứa log mysql
mkdir -p /var/log/mysql
chown mysql:mysql /var/log/mysql/
chown -R root:nginx /var/lib/php

# Cấu hình nginx
rm -rf /etc/nginx/conf.d/php-fpm.conf
rm -rf /etc/nginx/default.d/php.conf

process=$(grep -c ^processor /proc/cpuinfo)
max_client=$(expr 1024 \* $process \* 2)

mkdir -p /etc/larvps/user
mkdir -p /etc/larvps/lets_encrypt
mkdir -p /etc/larvps/custom_nginx
mkdir -p /etc/larvps/nginx
touch /etc/larvps/nginx/global.conf

cat > "/etc/larvps/nginx/global.conf" <<END
map \$http_accept \$webp_suffix {
  default "";
  "~*webp" ".webp";
}
END

sed -i "s/user = apache/user = nginx/g" /etc/php-fpm.d/www.conf
sed -i "s/group = apache/group = nginx/g" /etc/php-fpm.d/www.conf

cat > "/etc/nginx/nginx.conf" <<END
user nginx;
worker_processes $process;
worker_rlimit_nofile 260000;
error_log /var/log/nginx/error.log;
pid /var/run/nginx.pid;
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections $max_client;
    accept_mutex off;
    accept_mutex_delay 200ms;
    use epoll;
    multi_accept on;
}

http {
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log off;

    add_header X-Frame-Options SAMEORIGIN;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options nosniff;

    fastcgi_hide_header X-Powered-By;
    proxy_hide_header X-Powered-By;
    server_tokens off;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay off;
    types_hash_max_size 2048;
    server_names_hash_bucket_size 128;
    client_max_body_size 0;
    client_body_buffer_size 256k;
    client_body_in_file_only off;
    client_body_timeout 60s;
    client_header_buffer_size 256k;
    client_header_timeout  30s;
    large_client_header_buffers 8 256k;
    keepalive_timeout 10;
    keepalive_disable msie6;
    reset_timedout_connection on;
    send_timeout 300s;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    gzip on;
    gzip_static on;
    gzip_disable msie6;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 2;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_min_length 256;
    gzip_types
        text/css
        text/javascript
        text/xml
        text/plain
        text/x-component
        application/javascript
        application/x-javascript
        application/json
        application/xml
        application/rss+xml
        application/atom+xml
        font/truetype
        font/opentype
        application/vnd.ms-fontobject
        image/svg+xml;
    
    include /etc/larvps/nginx/global.conf;
    include /etc/nginx/conf.d/*.conf;
}
END


mkdir -p /etc/nginx/ssl
openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048
    
expect -c "
spawn sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt
expect \"letter\"
send \"VN\r\"
expect \"full\"
send \"Nginx\r\"
expect \"city\"
send \"Nginx\r\"
expect \"company\"
send \"Nginx\r\"
expect \"Name\"
send \"Nginx\r\"
expect \"Name\"
send \"Nginx\r\"
expect \"Address\"
send \"nginx@gmail.com\r\"
expect eof
"


cat > "/etc/nginx/conf.d/default.conf" <<END
server {
    server_name _;
    listen 80 default_server;
    return 404;
}

server {
    listen 443 ssl default_server;
    server_name _;
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;
    ssl_session_tickets off;
    return 404;
}


server {
    listen 6789;
    server_name larvps;
    root /usr/share/nginx/larvps;

    auth_basic "Restricted";
    auth_basic_user_file /usr/share/nginx/larvps/passwd/.htpasswd;

    index index.php index.html index.htm;
    location / {
         try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_intercept_errors on;
        fastcgi_index  index.php;
        fastcgi_connect_timeout 1000;
        fastcgi_send_timeout 1000;
        fastcgi_read_timeout 1000;
        fastcgi_buffer_size 256k;
        fastcgi_buffers 4 256k;
        fastcgi_busy_buffers_size 256k;
        fastcgi_temp_file_write_size 256k;
        include        fastcgi_params;
        fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
        fastcgi_pass unix:/run/php-fpm/www.sock;
    }
}
END

systemctl reload nginx.service

pkill -9 nginx
nginx -c /etc/nginx/nginx.conf
nginx -s reload
pkill -f nginx & wait $!
systemctl start nginx


#Cấu hình mariadb
mysql << EOF
use mysql;
FLUSH PRIVILEGES;
CREATE USER 'admin'@'localhost' IDENTIFIED BY '$db_root_password';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;
DROP USER 'root'@'localhost';
FLUSH PRIVILEGES;
EOF


#Cài đặt phpmyadmin
cd /usr/share/nginx/larvps
wget https://files.phpmyadmin.net/phpMyAdmin/$phpmyadmin_version/phpMyAdmin-$phpmyadmin_version-all-languages.zip
unzip phpMyAdmin-$phpmyadmin_version-all-languages.zip
mv phpMyAdmin-$phpmyadmin_version-all-languages phpmyadmin
rm -f phpMyAdmin-$phpmyadmin_version-all-languages.zip
cp /usr/share/nginx/larvps/phpmyadmin/config.sample.inc.php  /usr/share/nginx/larvps/phpmyadmin/config.inc.php
secret=$(openssl rand -base64 32)
echo "\$cfg['TempDir'] = '/var/lib/phpmyadmin/tmp';" >> /usr/share/nginx/larvps/phpmyadmin/config.inc.php
echo "\$cfg['blowfish_secret'] = '$secret';" >> /usr/share/nginx/larvps/phpmyadmin/config.inc.php
mkdir -p /var/lib/phpmyadmin/tmp
chmod 700 /var/lib/phpmyadmin/tmp
chown nginx:nginx /var/lib/phpmyadmin/tmp
chown -hR nginx:nginx /usr/share/nginx/larvps/phpmyadmin


#opcache
cd /usr/share/ /larvps 
curl -sO "https://larvps.com/scripts/configs/tool/opcache-gui-master.zip"
unzip /usr/share/nginx/larvps/opcache-gui-master.zip
rm -f /usr/share/nginx/larvps/opcache-gui-master.zip
mv -f /usr/share/nginx/larvps/opcache-gui-master /usr/share/nginx/larvps/opcache
chown -hR nginx:nginx /usr/share/nginx/larvps/opcache

#phpmemcachedadmin
cd /usr/share/nginx/larvps
curl -sO "https://larvps.com/scripts/configs/tool/phpmemcachedadmin-master.zip"
unzip /usr/share/nginx/larvps/phpmemcachedadmin-master.zip
rm -f /usr/share/nginx/larvps/phpmemcachedadmin-master.zip
mv -f /usr/share/nginx/larvps/phpmemcachedadmin-master /usr/share/nginx/larvps/phpmemcachedadmin
chown -hR nginx:nginx /usr/share/nginx/larvps/phpmemcachedadmin

#cài đặt ssl
# curl -O https://dl.eff.org/certbot-auto
# chmod a+x certbot-auto
# mv -f certbot-auto /usr/bin/certbot

# dnf install epel-release -y
# dnf upgrade -y
# yum install snapd -y
# systemctl enable --now snapd.socket
# ln -s /var/lib/snapd/snap /snap
# snap install core; snap refresh core
# snap install --classic certbot
# rm -f /usr/bin/certbot
# ln -s /snap/bin/certbot /usr/bin/certbot

# expect -c "
# spawn certbot --nginx --agree-tos --register-unsafely-without-email
# set timeout 35
# expect \"ok\"
# send \"y\r\"
# expect eof
# "

# curl https://get.acme.sh | sh -s email=info@lả.com

# Cài đặt memcached
dnf -y install memcached php-pecl-memcached php-pecl-memcache
cat > "/etc/sysconfig/memcached" <<END
PORT="11211"
USER="memcached"
MAXCONN="$max_client"
CACHESIZE="128"
OPTIONS="-l 127.0.0.1 -U 0"
END


## cài đặt redis,  /etc/redis.conf
yum install redis -y
yum install -y php-pecl-redis5


## lưu file cấu hình
mkdir -p /etc/larvps/
cat > "/etc/larvps/.larvps.conf" <<END
ip=$ip
version=$larvps_version
port_ssh=$port_ssh
phpmyadmin_version=$phpmyadmin_version
port_admin=$port_admin
db_admin_password=$db_root_password
ad_password=$admin_root_password
END

## tạo menu LarVPS
cd
wget "https://larvps.com/scripts/menu.zip" 
unzip -o menu.zip
cd menu
mv larvps /usr/bin/
cd ..
mv menu /etc/larvps/
rm -f menu.zip
rm -rf __MACOSX

# shortcut
mv -f /etc/larvps/menu/action/shortcut/add /usr/bin/add
mv -f /etc/larvps/menu/action/shortcut/delete /usr/bin/delete
mv -f /etc/larvps/menu/action/shortcut/list /usr/bin/list
mv -f /etc/larvps/menu/action/shortcut/restart /usr/bin/restart
mv -f /etc/larvps/menu/action/shortcut/stop /usr/bin/stop
mv -f /etc/larvps/menu/action/shortcut/backup /usr/bin/backup
mv -f /etc/larvps/menu/action/shortcut/check /usr/bin/check


# 0.1.4
echo "cd /home" >> /root/.bashrc
echo ". /etc/larvps/menu/status" >> /root/.bashrc
echo ". /etc/larvps/menu/check" >> /root/.bashrc

echo "alias 00='. /etc/larvps/menu/permission_all'" >> /root/.bashrc
echo "alias 0='larvps'" >> /root/.bashrc
echo "alias 01='. /etc/larvps/menu/action/larvps_update/update_larvps'" >> /root/.bashrc
echo "alias 02='. /etc/larvps/reload_menu'" >> /root/.bashrc

# echo 'alias larvps=". /etc/larvps/menu/larvps"' >> /root/.bashrc

chmod 700 /usr/bin/perl
chmod 700 /etc/passwd

#0.1.6.1
yum -y install php-pecl-zip

#0.1.6.4
mkdir -p /var/lib/php/session
chown nginx:nginx /var/lib/php/session
chmod 755 /var/lib/php/session

ram_total=$(cat /proc/meminfo | grep 'MemTotal' |cut -f2 -d':' | xargs | cut -f1 -d' ')
if [[ "$ram_total" -gt "524288" && "$ram_total" -le "1049576" ]] ; then
    wget -q $script_url/configs/mysql/0.5gb.cnf -O /etc/my.cnf
    wget -q $script_url/configs/php/0.5gb.ini -O /etc/php.d/00-larvps-custom.ini

elif [[ "$ram_total" -gt "1049576" && "$ram_total" -le "2099152" ]]; then
    wget -q $script_url/configs/mysql/1gb.cnf -O /etc/my.cnf
    wget -q $script_url/configs/php/1gb.ini -O /etc/php.d/00-larvps-custom.ini

elif [[ "$ram_total" -gt "2099152" && "$ram_total" -le "4198304" ]]; then
    wget -q $script_url/configs/mysql/2gb.cnf -O /etc/my.cnf
    wget -q $script_url/configs/php/2gb.ini -O /etc/php.d/00-larvps-custom.ini

elif [[ "$ram_total" -gt "4198304" && "$ram_total" -le "8396608" ]]; then
    wget -q $script_url/configs/mysql/4gb.cnf -O /etc/my.cnf
    wget -q $script_url/configs/php/4gb.ini -O /etc/php.d/00-larvps-custom.ini
elif [[ "$ram_total" -gt "8396608" && "$ram_total" -le "16793216" ]]; then

    wget -q $script_url/configs/mysql/8gb.cnf -O /etc/my.cnf
    wget -q $script_url/configs/php/8gb.ini -O /etc/php.d/00-larvps-custom.ini

elif [[ "$ram_total" -gt "16793216" && "$ram_total" -le "33586432" ]]; then
    wget -q $script_url/configs/mysql/16gb.cnf -O /etc/my.cnf
    wget -q $script_url/configs/php/16gb.ini -O /etc/php.d/00-larvps-custom.ini
else
    wget -q $script_url/configs/mysql/32gb.cnf -O /etc/my.cnf
    wget -q $script_url/configs/php/32gb.ini -O /etc/php.d/00-larvps-custom.ini
fi


#install mod ssl
yum -y install nginx mod_ssl
systemctl enable --now nginx


#rclone
# cd ~
# curl -O https://downloads.rclone.org/v1.57.0/rclone-v1.57.0-linux-amd64.zip
# unzip rclone-v1.57.0-linux-amd64.zip
# cd rclone-v1.57.0-linux-amd64
# mv -f rclone /usr/bin/
sudo -v curl https://rclone.org/install.sh | sudo bash


#tạo folder
mkdir -p /etc/larvps/cron/backup
mkdir -p /etc/larvps/cron/alert
mkdir -p /etc/larvps/custom-nginx

chmod u+x /etc/larvps/cron/backup/hourly>>/etc/larvps/cron/backup/hourly
chmod u+x /etc/larvps/cron/backup/quarter_daily>>/etc/larvps/cron/backup/quarter_daily
chmod u+x /etc/larvps/cron/backup/half_daily>>/etc/larvps/cron/backup/half_daily
chmod u+x /etc/larvps/cron/backup/daily>>/etc/larvps/cron/backup/daily
chmod u+x /etc/larvps/cron/backup/weekly>>/etc/larvps/cron/backup/weekly
chmod u+x /etc/larvps/cron/backup/monthly>>/etc/larvps/cron/backup/monthly

chmod u+x /etc/larvps/cron/alert/minute>>/etc/larvps/cron/alert/minute
chmod u+x /etc/larvps/cron/alert/five_minutes>>/etc/larvps/cron/alert/five_minutes
chmod u+x /etc/larvps/cron/alert/ten_minutes>>/etc/larvps/cron/alert/ten_minutes
chmod u+x /etc/larvps/cron/alert/half_hourly>>/etc/larvps/cron/alert/half_hourly
chmod u+x /etc/larvps/cron/alert/hourly>>/etc/larvps/cron/alert/hourly
chmod u+x /etc/larvps/cron/alert/daily>>/etc/larvps/cron/alert/daily
chmod u+x /etc/larvps/cron/alert/weekly>>/etc/larvps/cron/alert/weekly
chmod u+x /etc/larvps/cron/alert/monthly>>/etc/larvps/cron/alert/monthly

# cron daily
# cat > "/etc/larvps/cron/alert/daily" <<END
# . /etc/larvps/menu/centos_security
# END

# add to crontab
cat <(crontab -l) <(echo "0 * * * * /etc/larvps/cron/backup/hourly >> /dev/null 2>&1") | crontab -
cat <(crontab -l) <(echo "0 */6 * * * /etc/larvps/cron/backup/quarter_daily >> /dev/null 2>&1") | crontab -
cat <(crontab -l) <(echo "0 */12 * * * /etc/larvps/cron/backup/half_daily >> /dev/null 2>&1") | crontab -
cat <(crontab -l) <(echo "0 1 * * * /etc/larvps/cron/backup/daily >> /dev/null 1>&1") | crontab -
cat <(crontab -l) <(echo "0 1 * * 0 /etc/larvps/cron/backup/weekly >> /dev/null 1>&1") | crontab -
cat <(crontab -l) <(echo "0 1 1 * * /etc/larvps/cron/backup/monthly >> /dev/null 2>&1") | crontab -

cat <(crontab -l) <(echo "* * * * * /etc/larvps/cron/alert/minute >> /dev/null 2>&1") | crontab -
cat <(crontab -l) <(echo "*/5 * * * * /etc/larvps/cron/alert/five_minutes >> /dev/null 2>&1") | crontab -
cat <(crontab -l) <(echo "*/10 * * * * /etc/larvps/cron/alert/ten_minutes >> /dev/null 2>&1") | crontab -
cat <(crontab -l) <(echo "*/30 * * * * /etc/larvps/cron/alert/half_hourly >> /dev/null 2>&1") | crontab -
cat <(crontab -l) <(echo "0 * * * * /etc/larvps/cron/alert/hourly >> /dev/null 2>&1") | crontab -
cat <(crontab -l) <(echo "0 2 * * * /etc/larvps/cron/alert/daily >> /dev/null 2>&1") | crontab -
cat <(crontab -l) <(echo "0 2 * * 0 /etc/larvps/cron/alert/weekly >> /dev/null 2>&1") | crontab -
cat <(crontab -l) <(echo "0 2 1 * * /etc/larvps/cron/alert/monthly >> /dev/null 2>&1") | crontab -
cat <(crontab -l) <(echo "0 1 * * * /etc/larvps/menu/action/zero_ssl/renew_zerossl >> /dev/null 2>&1") | crontab -


service crond restart

# disable httpd
systemctl stop httpd
systemctl disable httpd
systemctl mask httpd


cd /etc/nginx
git clone https://github.com/satellitewp/rocket-nginx.git
cd rocket-nginx
mv rocket-nginx.ini.disabled rocket-nginx.ini
php rocket-parser.php

#
# cp /lib/systemd/system/mysql.service /etc/systemd/system/
# sed -i '/LimitNOFILE/d' /etc/systemd/system/mysql.service
# sed -i '/LimitMEMLOCK/d' /etc/systemd/system/mysql.service
# echo "LimitNOFILE=infinity" >> /etc/systemd/system/mysql.service
# echo "LimitMEMLOCK=infinity" >> /etc/systemd/system/mysql.service
# systemctl daemon-reload

setsebool -P nis_enabled 1
ausearch -c 'php-fpm' --raw | audit2allow -M my-phpfpm
semodule -X 300 -i my-phpfpm.pp
setsebool -P httpd_read_user_content 1

#wp-cli
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
php wp-cli.phar --info
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

#auto update security
sed -i 's/upgrade_type = default/update_type = security/' /etc/dnf/automatic.conf
sed -i 's/emit_via = stdio/update_type = none/' /etc/dnf/automatic.conf
systemctl enable --now dnf-automatic.timer

# iconcube
cd
wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
tar xzf ioncube_loaders_lin_x86-64.tar.gz
mv ioncube /usr/local/
rm -f ioncube_loaders_lin_x86-64.tar.gz

# add swap
swapoff -a -v
rm -rf /var/swap.1
/bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=1024
/sbin/mkswap /var/swap.1
/sbin/swapon /var/swap.1
sed -i '/swap.1/d' /etc/fstab
echo /var/swap.1 none swap defaults 0 0 >> /etc/fstab

sysctl vm.swappiness=10
echo vm.swappiness=10 >> /etc/sysctl.conf

ln -s /etc/larvps/menu/transfer /usr/bin

openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

cat > "/etc/nginx/ssl_config.conf" <<END
ssl_session_cache shared:SSL_LET:10m;
ssl_session_timeout  10m;
ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
ssl_ecdh_curve secp384r1;
ssl_prefer_server_ciphers on;
ssl_session_tickets off;
resolver 8.8.8.8 valid=300s;
resolver_timeout 5s;
ssl_dhparam /etc/nginx/ssl/dhparam.pem;
END

cd /etc/larvps/
wget https://larvps.com/scripts/tld.txt


if [[ ! -f "/etc/nginx/cloudflare" ]]; then
    
CLOUDFLARE_FILE_PATH=/etc/nginx/cloudflare

echo "#Cloudflare" > $CLOUDFLARE_FILE_PATH;
echo "" >> $CLOUDFLARE_FILE_PATH;

echo "# - IPv4" >> $CLOUDFLARE_FILE_PATH;
for i in `curl https://www.cloudflare.com/ips-v4`; do
    echo "set_real_ip_from $i;" >> $CLOUDFLARE_FILE_PATH;
done

echo "" >> $CLOUDFLARE_FILE_PATH;
echo "# - IPv6" >> $CLOUDFLARE_FILE_PATH;
for i in `curl https://www.cloudflare.com/ips-v6`; do
    echo "set_real_ip_from $i;" >> $CLOUDFLARE_FILE_PATH;
done

echo "" >> $CLOUDFLARE_FILE_PATH;
echo "real_ip_header CF-Connecting-IP;" >> $CLOUDFLARE_FILE_PATH;

echo "include /etc/nginx/cloudflare;" >> /etc/larvps/global.conf
fi


clear
echo "========================================================================="
echo "                        Cai dat thanh cong                               "
echo "========================================================================="
echo "              Luu lai thong tin ben duoi de truy cap ve sau              "
echo "-------------------------------------------------------------------------"
echo "1.   ssh                : ssh -p $port_ssh $current_user@$ip"
echo "2.   ip_vps             : $ip"
echo "3.   port_ssh           : $port_ssh"
echo "4.   php_my_admin       : http://$ip:$port_admin/phpmyadmin"
echo "5.   db_admin_username  : admin"
echo "6.   db_admin_password  : $db_root_password"
echo "7.   admin_Login        : admin"
echo "8.   admin_password     : $admin_root_password"
echo "-------------------------------------------------------------------------"

echo ""
echo "Ban co the su dung host de xem lai thong tin tren VPS."
echo "VPS se khoi dong lai."
cat > "/etc/larvps/.info.conf" <<END
=========================================================================
                 Sao luu thong tin cai dat goc
=========================================================================
1.   ssh                : ssh -p $port_ssh $current_user@$ip
2.   ip_vps             : $ip
3.   port_ssh           : $port_ssh
4.   php_my_admin       : http://$ip:$port_admin/phpmyadmin
5.   db_admin_username  : admin
6.   db_admin_password  : $db_root_password
7.   admin_Login        : admin
8.   admin_password     : $admin_root_password
-------------------------------------------------------------------------
END

echo
echo
cd && rm -f larvps
sleep 3
reboot
