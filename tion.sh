#!/bin/bash
# @author: LÃ£ng Tá»­ CÃ´ Äá»™c
# @website:  https://tinohost.com, https://kienthuclinux.com
# @since: 2020


gen_pass() {
    MATRIX='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
    LENGTH=16
    while [ ${n:=1} -le $LENGTH ]; do
        PASS="$PASS${MATRIX:$(($RANDOM%${#MATRIX})):1}"
        let n+=1
    done
    echo "$PASS"
}

## tinopool func

TINOPOOL(){
cd /opt/php/php$sock_tino/etc/php-fpm.d/
cat > "/opt/php/php$sock_tino/etc/php-fpm.d/tinopanel.conf" <<END
[tinopanel]
listen = /dev/shm/tinopanel.$sock_tino.sock;
user = tinopanel
group = tinopanel
listen.owner = nginx
listen.group = nginx
listen.mode = 0644
;listen.allowed_clients = 127.0.0.1
pm = ondemand
pm.max_children = 15
pm.start_servers = 5
pm.min_spare_servers = 3
pm.max_spare_servers = 10
pm.max_requests = 500
END

#cat >>  /opt/php/php$sock_tino/lib/php.ini <<END
#zend_extension=opcache.so
#opcache.enable=1
#opcache.enable_cli=1
#opcache.memory_consumption=128
#opcache.interned_strings_buffer=16
#opcache.max_accelerated_files=4000
#opcache.max_wasted_percentage=5
#opcache.use_cwd=1
#opcache.validate_timestamps=1
#opcache.revalidate_freq=60
#opcache.fast_shutdown=1
#opcache.blacklist_filename=/etc/opcache-default.blacklist
#END
cat > /etc/opcache-default.blacklist <<END
/home/*/public_html/wp-content/plugins/backwpup/*
/home/*/public_html/wp-content/plugins/duplicator/*
/home/*/public_html/wp-content/plugins/updraftplus/*
/opt/tinopanel/private_html/
END

rm -rf /opt/php/php$sock_tino/etc/php-fpm.d/www.conf

}



## func nginx

CREATE_USER_NGINX() {
	if [ ! `cat /etc/passwd | grep nginx` ]; then
		groupadd -r nginx 
        useradd -r -s /sbin/nologin -M -c "nginx service" -g nginx nginx
		echo "Finished create user nginx, continues create startup script..."
		sleep 5
	else
		echo "existed user nginx, continues create startup script..."
		sleep 5
fi
}



CREATE_STARTUP_SCRIPT_NGX() {

mkdir -p /var/cache/nginx  >/dev/null 2>&1
mkdir -p /var/log/nginx  >/dev/null 2>&1


cat > "/etc/nginx/nginx.conf" <<END
user nginx nginx;
worker_processes auto;
worker_rlimit_nofile 8192;

error_log /var/log/nginx/error.log notice;
pid /var/run/nginx.pid;
include /usr/share/nginx/modules/*.conf;
pcre_jit on;

events
{
	worker_connections 1024;
	use epoll;
}

http
{
	server_names_hash_max_size 2048;
	server_tokens off;
	more_set_headers 'Server: tino-panel';
	vhost_traffic_status_zone;

	geoip2 /usr/share/GeoIP/GeoLite2-Country.mmdb
	{
		auto_reload 60m;
		\$geoip2_metadata_country_build metadata build_epoch;
		\$geoip2_data_country_code country iso_code;
		\$geoip2_data_country_name country names en;
	}
	geoip2 /usr/share/GeoIP/GeoLite2-City.mmdb
	{
		auto_reload 60m;
		\$geoip2_metadata_city_build metadata build_epoch;
		\$geoip2_data_city_name city names en;
	}

	add_header X-GeoCountry \$geoip2_data_country_name;
	add_header X-GeoCode \$geoip2_data_country_code;
	add_header X-GeoCity \$geoip2_data_city_name;

	map \$geoip2_data_country_code \$allowed_country
	{
		default yes;
		VN yes;
		US yes;
	}


	geo \$whitelist
	{
		default 0;
		# CIDR in the list below are not limited
		1.2.3.0/24 1;
		9.10.11.12/32 1;
		127.0.0.1/32 1;
		#     $server_ip 1;
	}

	map \$whitelist \$limit
	{
		0 \$binary_remote_addr;
		1 "";
	}


	map \$http_host \$blogid
	{
		default -999;
	}
	geo \$allowed_ip
	{
		default yes;
		127.0.0.1 yes;
		192.168.1.0/24 yas;
	}
	server_names_hash_bucket_size 1024;

	include /etc/nginx/mime.types;
	default_type application/octet-stream;

	log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
	'\$status \$body_bytes_sent "\$http_referer" '
	'"\$http_user_agent" "\$http_x_forwarded_for" '
	'\$request_time \$upstream_response_time \$pipe';

	disable_symlinks if_not_owner;

	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;
	types_hash_max_size 2048;
	variables_hash_max_size 1024;
	variables_hash_bucket_size 128;

	keepalive_requests 300;
	keepalive_timeout 30;

	client_body_temp_path /var/lib/nginx/cache/client_body 1 2;
	client_max_body_size 512M;
	client_body_buffer_size 2048k;
	client_body_timeout 30s;
	client_header_timeout 30s;

	connection_pool_size 256;


	## Include Gzip-brotli
	include /etc/nginx/gzip.conf;

	## General Options
	index index.html index.php;
	charset UTF-8;
	ignore_invalid_headers on;

	## pagespeed options
	include /etc/nginx/pagespeed.conf;

	## proxy - fast cgi options
	include /etc/nginx/proxy.conf;


	upstream php
	{
		#server 127.0.0.1:9000;
		server unix:/dev/shm/tinopanel.$sock_tino.sock;
	}

	include /etc/nginx/conf.d/vhosts/*.conf;
	include /etc/nginx/conf.d/custom/blacklist.conf;
	include /etc/nginx/conf.d/custom/cloudflare.conf;
}
END

cat > "/etc/nginx/gzip.conf" <<END
    brotli on;
    brotli_static on;
    brotli_buffers 16 8k;
    brotli_comp_level 6;
    brotli_types
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
        application/vnd.ms-fontobject
        font/truetype
        font/opentype
        image/svg+xml;
        
    gzip on;
    gzip_disable "MSIE [1-6]\.";
    gzip_static on;
    gzip_comp_level 9;
    gzip_http_version 1.1;
    gzip_proxied any;
    gzip_vary on;
    gzip_buffers 16 8k;
    gzip_min_length 1100;
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
        application/vnd.ms-fontobject
        font/truetype
        font/opentype
        image/svg+xml;
END

cat > "/etc/nginx/pagespeed.conf" <<END

    pagespeed off;
    pagespeed FileCachePath /var/lib/nginx/cache/pagespeed;
    pagespeed FileCacheSizeKb 204800;
    pagespeed FileCacheCleanIntervalMs 3600000;
    pagespeed FileCacheInodeLimit 100000;
    pagespeed MemcachedThreads 1;
    pagespeed MemcachedServers "localhost:11211";
    pagespeed MemcachedTimeoutUs 100000;
    pagespeed RewriteLevel CoreFilters;
    pagespeed EnableFilters collapse_whitespace,remove_comments,extend_cache;
    pagespeed DisableFilters combine_css,combine_javascript;
    pagespeed LowercaseHtmlNames on;
    pagespeed StatisticsPath /ngx_pagespeed_statistics;
    pagespeed GlobalStatisticsPath /ngx_pagespeed_global_statistics;
    pagespeed MessagesPath /ngx_pagespeed_message;
    pagespeed ConsolePath /pagespeed_console;
    pagespeed AdminPath /pagespeed_admin;
    pagespeed GlobalAdminPath /pagespeed_global_admin;
    pagespeed MessageBufferSize 100000;
    pagespeed UsePerVhostStatistics on;
    pagespeed FetchHttps enable;
    pagespeed FetchHttps enable,allow_self_signed;
    pagespeed SslCertDirectory /etc/pki/tls/certs;
    pagespeed SslCertFile /etc/pki/tls/cert.pem;
    pagespeed EnableCachePurge on;
    pagespeed InPlaceResourceOptimization on;
    
END


if (( ${system_version} == 9 ));then
    echo "" > /etc/nginx/pagespeed.conf
fi

    
cat > "/etc/nginx/proxy.conf" <<END
    proxy_cache_path /var/lib/nginx/cache/proxy levels=1:2 keys_zone=PROXYCACHE:100m max_size=200m inactive=60m;
    proxy_temp_path /var/lib/nginx/cache/proxy_tmp;
    proxy_connect_timeout 30;
    proxy_read_timeout 300;
    proxy_send_timeout 300;
    proxy_buffers 16 32k;
    proxy_buffering on;
    proxy_buffer_size 64k;
    proxy_busy_buffers_size 96k;
    proxy_temp_file_write_size 96k;
    proxy_cache_key "\$scheme://\$host\$request_uri";

    fastcgi_cache_path /var/lib/nginx/cache/fastcgi levels=1:2 keys_zone=FCGICACHE:100m max_size=200m inactive=60m;
    fastcgi_temp_path /var/lib/nginx/cache/fastcgi_tmp;
    fastcgi_cache_key "\$scheme\$request_method\$host\$request_uri";
    fastcgi_cache_use_stale error timeout invalid_header http_500;
    fastcgi_ignore_headers Cache-Control Expires Set-Cookie;
    fastcgi_send_timeout 300;
    fastcgi_read_timeout 300;
    fastcgi_buffers 8 256k;
    fastcgi_buffer_size 256k;
    fastcgi_busy_buffers_size 256k;
    fastcgi_index index.php;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    
    #limit_req_zone \$binary_remote_addr zone=wplogin:50m rate=15r/m;
	limit_req_zone       \$limit   zone=wplogin:10m  rate=60r/m;
    #limit_req            zone=wplogin burst=3;
    #limit_req_log_level  warn;
    #limit_req_status     503;
END


cat > "/etc/nginx/fastcgi.conf" <<END
fastcgi_param  SCRIPT_FILENAME    \$document_root\$fastcgi_script_name;
fastcgi_param  QUERY_STRING	  \$query_string;
fastcgi_param  REQUEST_METHOD     \$request_method;
fastcgi_param  CONTENT_TYPE	  \$content_type;
fastcgi_param  CONTENT_LENGTH     \$content_length;

fastcgi_param  SCRIPT_NAME        \$fastcgi_script_name;
fastcgi_param  REQUEST_URI        \$request_uri;
fastcgi_param  DOCUMENT_URI	  \$document_uri;
fastcgi_param  DOCUMENT_ROOT	  \$document_root;
fastcgi_param  SERVER_PROTOCOL    \$server_protocol;
fastcgi_param  REQUEST_SCHEME     \$scheme;
fastcgi_param  HTTPS              \$https if_not_empty;

fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
fastcgi_param  SERVER_SOFTWARE    nginx/\$nginx_version;

fastcgi_param  REMOTE_ADDR        \$remote_addr;
fastcgi_param  REMOTE_PORT        \$remote_port;
fastcgi_param  SERVER_ADDR        \$server_addr;
fastcgi_param  SERVER_PORT        \$server_port;
fastcgi_param  SERVER_NAME        \$server_name;

# PHP only, required if PHP was built with --enable-force-cgi-redirect
fastcgi_param  REDIRECT_STATUS    200;
END
cat > "/etc/nginx/fastcgiproxy.conf" <<END
set_real_ip_from 199.27.128.0/21;
set_real_ip_from 173.245.48.0/20;
set_real_ip_from 103.21.244.0/22;
set_real_ip_from 103.22.200.0/22;
set_real_ip_from 103.31.4.0/22;
set_real_ip_from 141.101.64.0/18;
set_real_ip_from 108.162.192.0/18;
set_real_ip_from 190.93.240.0/20;
set_real_ip_from 188.114.96.0/20;
set_real_ip_from 197.234.240.0/22;
set_real_ip_from 198.41.128.0/17;
set_real_ip_from 162.158.0.0/15;
set_real_ip_from 104.16.0.0/12;
set_real_ip_from 172.64.0.0/13;
set_real_ip_from 2400:cb00::/32;
set_real_ip_from 2606:4700::/32;
set_real_ip_from 2803:f800::/32;
set_real_ip_from 2405:b500::/32;
set_real_ip_from 2405:8100::/32;
real_ip_header CF-Connecting-IP;
real_ip_recursive on;
END
}

# func php-fpm

COMPILE_PHP() {
cd $tino

mkdir -p /opt/php/

for x in php$sock_tino php$sock_tino-php-calendar php$sock_tino-php-gd php$sock_tino-php-curl php$sock_tino-php-inline-optimization php$sock_tino-php-bz2 php$sock_tino-php-zlib php$sock_tino-php-sockets php$sock_tino-php-sysvsem php$sock_tino-php-sysvshm php$sock_tino-php-pcntl php$sock_tino-php-mbregex php$sock_tino-php-mhash php$sock_tino-php-pdo-mysql php$sock_tino-php-mysqli php$sock_tino-php-openssl php$sock_tino-php-ftp php$sock_tino-php-opcache php$sock_tino-php-bcmath php$sock_tino-php-fpm  php$sock_tino-php-mbstring php$sock_tino-php-pear  php$sock_tino-php-freetype php$sock_tino-php-jpeg php$sock_tino-php-soap php$sock_tino-php-intl  php$sock_tino-php-exif  php$sock_tino-php-pecl-zip php$sock_tino-php-redis php$sock_tino-php-memcached php$sock_tino-php-imagick  php$sock_tino-php-ioncube-loader php$sock_tino-php-zstd php$sock_tino-php-xmlrpc php$sock_tino-php-pgsql php$sock_tino-php-imap php$sock_tino-php-brotli
do
yum install $x -y
done

if [ "$sock_tino" -lt 56 ]; then
  ln -s /opt/remi/php$sock_tino/root/etc /etc/opt/remi/php$sock_tino
  
fi

ln -s /etc/opt/remi/php$sock_tino/ /opt/php/
ln -s /etc/opt/remi/php$sock_tino/ /opt/php/php$sock_tino/etc
unlink /etc/opt/remi/php$sock_tino/php$sock_tino
ln -s /opt/remi/php$sock_tino/root/bin/ /opt/php/php$sock_tino/

mkdir -p /opt/php/php$sock_tino/var/
ln -sf /var/opt/remi/php$sock_tino/run /opt/php/php$sock_tino/var/


mkdir -p /opt/php/php$sock_tino/lib/
sleep 5

ln -sf /etc/opt/remi/php$sock_tino/php.ini /opt/php/php$sock_tino/lib/


upload_max_filesize=2048M
post_max_size=2048M
max_execution_time=300
max_input_time=300
memory_limit=512M


for key in upload_max_filesize post_max_size max_execution_time max_input_time memory_limit
do
 sed -i "s/^\($key\).*/\1 $(eval echo = \${$key})/" /opt/php/php$sock_tino/etc/php.ini
done

for key in upload_max_filesize post_max_size max_execution_time max_input_time memory_limit
do
 sed -i "s/^\($key\).*/\1 $(eval echo = \${$key})/" /etc/opt/remi/php$sock_tino/php.ini 
done



cat > "/opt/php/php$sock_tino/etc/php-fpm.conf" <<END
[global]
pid = run/php-fpm.pid
include=/opt/php/php$sock_tino/etc/php-fpm.d/*.conf
END
mkdir -p /opt/php/php$sock_tino/etc/php-fpm.d/ >/dev/null 2>&1
ln -s /lib/systemd/system/php$sock_tino-php-fpm.service /lib/systemd/system/php-fpm-$sock_tino.service
}



###startinstall
###########
cat > "/etc/environment" <<END
LANG=en_US.utf-8
LC_ALL=en_US.utf-8
END

#system_version=$(hostnamectl | grep "Operating System" | cut -f2 -d":" | cut -f4 -d" ")


#system_version=$(rpm -E %{rhel})
#if [[ "$system_version" != "7" ]]; then
#echo "Tino Script chi ho tro Centos 7"
#rm -rf tinovps-install
#exit
#fi

echo "TinoScript Ho tro RHEL 7,8,9 : Centos (7,8,9) ; Almalinux (8,9) ..."

sleep 5

## check panel install

if [ -d /usr/local/cpanel ]; then
	echo -e "\ncPanel detected...exit...\n"
	exit 1
fi
if [ -d /opt/plesk ]; then
	echo -e "\nPlesk detected...exit...\n"
	exit 1
fi

## check service

if systemctl is-active --quiet httpd; then
	echo -e "\nhttpd process detected, exit...\n"
	exit
fi
if systemctl is-active --quiet apache2; then
	echo -e "\napache2 process detected, exit...\n"
	exit
fi
if systemctl is-active --quiet named; then
	echo -e "\nnamed process detected, exit...\n"
	exit
fi
if systemctl is-active --quiet mysqld; then
	echo -e "\nmysql process detected, exit...\n"
	exit
fi
if systemctl is-active --quiet exim; then
	echo -e "\nexim process detected, exit...\n"
	exit
fi
if systemctl is-active --quiet nginx; then
	echo -e "\nnginx process detected, exit...\n"
	exit
fi



## check root


system_version=$(rpm -E %{rhel})

yum -y install gawk bc wget lsof
clear
sleep 2
echo "Moi phien ban php ban cai dat them se chiem khoang 200MB dung luong O cung va 15MB RAM"
echo "De moi chuc nang tren VPS hoat dong on dinh, Chung toi khuyen dung VPS co tu 2GB ram tro len"
echo "****************************************"
echo "RHEL 7 (centos 7 ...) Support version php : 5.4 --> 8.2"
echo "RHEL 8 (centos 8, almalinux 8 ...) Support version php : 5.6 --> 8.2"
echo "RHEL 9 (centos 9, almalinux 9 ...) Support version php : 7.4 --> 8.2"
echo "****************************************"
echo ""

arr_ver=("5.4" "5.5" "5.6" "7.0" "7.1" "7.2" "7.3" "7.4" "8.0" "8.1" "8.2")
arr_go=("5_4" "5_5" "5_6" "7_0" "7_1" "7_2" "7_3" "7_4" "8_0" "8_1" "8_2")
arr_sock=("54" "55" "56" "70" "71" "72" "73" "74" "80" "81" "82")

php_version="7.4"; # Default PHP 7.4
php_go="7_4";
sock_tino=74;

prompt="Nhap vao lua chon cua ban [1-8]: "
options=("Cai dat PHP 5.4" "Cai dat PHP 5.5" "Cai dat PHP 5.6" "Cai dat PHP 7.0" "Cai dat PHP 7.1" "Cat dat PHP 7.2" "Cai dat PHP 7.3" "Cai dat PHP 7.4" "Cai dat PHP 8.0" "Cai dat PHP 8.1" "Cai dat PHP 8.2")
PS3="$prompt"




select opt in "${options[@]}" "Quit" ; do



    if (( REPLY == 1 + ${#options[@]} )) ; then
            echo "Thoat Cai Dat"
            sleep 2
        exit
	
    elif (( REPLY > 0 && REPLY <= ${#options[@]} )) ; then
                #echo $opt
        
		if (( REPLY < 3 && ${system_version} == 8 ));then
			echo "RHEL 8 (centos 8, almalinux 8 ...) Support version php : 5.6 --> 8.2"
		else

		if (( REPLY < 8 && ${system_version} == 9 ));then
		echo "RHEL 9 (centos 9, almalinux 9 ...) Support version php : 7.4 --> 8.2"
		else
				echo ${arr_go[$REPLY-1]}
                php_version=${arr_ver[$REPLY-1]}
       	       	php_go=${arr_go[$REPLY-1]}
       	       	sock_tino=${arr_sock[$REPLY-1]}
				break
		fi

		fi

    else
        echo "Wrong option, please try again: "
    fi
done



admin_port="7979"

echo "phien ban php cai dat la php $php_version , thoi gian cai dat khoang 5-15 phut" 


rm -f /etc/localtime
ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime

if [ -s /etc/selinux/config ]; then
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
fi
setenforce 0



if [[ "$system_version" != "7" ]]; then
echo "Update Centos 8"
cd /etc/yum.repos.d/
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* >/dev/null 2>&1
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-* >/dev/null 2>&1
yum install epel-release -y

yum update -y 
yum upgrade -y

curl -O https://raw.githubusercontent.com/AlmaLinux/almalinux-deploy/master/almalinux-deploy.sh && bash almalinux-deploy.sh

fi

# Install EPEL + Remi Repo
yum -y install epel-release yum-utils
yum install psmisc -y
rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-$system_version.rpm
yum -y install http://rpms.remirepo.net/enterprise/remi-release-$system_version.rpm
yum-config-manager --enable remi -y
yum update -y 

systemctl stop  saslauthd.service
systemctl disable saslauthd.service

# Disable the FirewallD Service and use Iptables instead because FirewallD need reboot in order to start
systemctl stop firewalld
systemctl disable firewalld
systemctl mask firewalld

yum -y remove mysql* php* httpd* sendmail* postfix* rsyslog*
yum clean all
yum -y update
yum install screen -y

#disable ipv6
echo "net.ipv6.conf.all.disable_ipv6 = 1" >>  /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >>  /etc/sysctl.conf
sysctl -p


mkdir -p /root/tino/

cd /root/tino/

yum install -y epel-release
yum install -y cmake3 cmake zlib-devel --enablerepo=epel 

for x in git wget zip unzip perl-ExtUtils-Embed pam-devel gcc gcc-c++ make geoip-devel httpd-tools libxml2-devel libXpm-devel gmp-devel libicu-devel t1lib-devel aspell-devel openssl-devel bzip2-devel libcurl-devel libjpeg-devel libvpx-devel libpng-devel freetype-devel readline-devel libtidy-devel libxslt-devel libmcrypt-devel pcre-devel curl-devel mysql-devel ncurses-devel gettext-devel net-snmp-devel libevent-devel libtool-ltdl-devel libc-client-devel postgresql-devel php-pecl-zip libzip-devel libuuid-devel  net-tools libmaxminddb gd sqlite-devel;
do
yum install $x -y
done

#yum --enablerepo=powertools install oniguruma-devel -y
#yum install  oniguruma-devel -y
#yum install ImageMagick-devel -y
#yum groupinstall -y 'Development Tools'



#yum remove -y libzip*
#yum remove -y libzip
#wget --no-check-certificate https://github.com/nih-at/libzip/releases/download/v1.10.0/libzip-1.10.0.tar.gz
#tar -zxvf libzip-1.10.0.tar.gz
#cd libzip-1.10.0
#mkdir build
#cd build
#cmake3 ..
#make
#make install


#echo '/usr/local/lib64
#/usr/local/lib
#/usr/lib
#/usr/lib64'>>/etc/ld.so.conf


sudo yum install libzip5 -y

memory=$(grep 'MemTotal' /proc/meminfo |tr ' ' '\n' |grep [0-9])

#----------------------------------------------------------#
#                      Checking swap                       #
#----------------------------------------------------------#

# Checking swap on small instances

if [ -z "$(swapon -s)" ] && [ $memory -lt 2000000 ]; then
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo "/swapfile   none    swap    sw    0   0" >> /etc/fstab
fi


# Install Others
for x in install exim syslog-ng syslog-ng-libdbi cronie unzip zip nano openssl ntpdate;
do
yum install $x -y
done

ntpdate asia.pool.ntp.org
hwclock --systohc

grep -q -F 'exclude=nginx*' /etc/yum.repos.d/epel.repo || sed -i '/\[epel\]/a\exclude=nginx*' /etc/yum.repos.d/epel.repo


## download file install 

#git clone https://github.com/tinopanel/tino.git
mkdir /root/tino
tino='/root/tino'


## cai dat php-fpm

#cd $tino
#mkdir php53
#cd php53
#wget --no-check-certificate https://www.php.net/distributions/$php_53.tar.gz
#tar -vzxf php*
#cd $tino
#mkdir php56
#cd php56
#wget --no-check-certificate https://www.php.net/distributions/$php_56.tar.gz
#tar -vzxf php*

CREATE_USER_NGINX
# install  php-fpm
useradd -M -s /bin/nologin tinopanel


yum  install re2c -y
yum remove bison -y 
cd /root/tino/

        COMPILE_PHP
        
        rm -rf /opt/php/php$sock_tino/etc/php-fpm.d/*
	    cd /opt/php/php$sock_tino/etc/php-fpm.d/
        TINOPOOL
        systemctl start php-fpm-$sock_tino.service
        systemctl enable php-fpm-$sock_tino.service
        echo "Finshed compile PHP $sock_tino,..."
                        sleep 10


##### cai dat nginx

nginx_version="1.24.0"
release_nginx="2"
cd /root/


wget --no-check-certificate https://scripts.tino.org/repo_nginx/$system_version/nginx-$nginx_version-$release_nginx.el$system_version.x86_64.rpm
wget --no-check-certificate https://scripts.tino.org/repo_nginx/$system_version/nginx-module-modsecurity-$nginx_version-$release_nginx.el$system_version.x86_64.rpm
wget --no-check-certificate https://scripts.tino.org/repo_nginx/$system_version/libmaxminddb-1.7.1-1.el$system_version.x86_64.rpm

yum localinstall /root/nginx-$nginx_version-$release_nginx.el$system_version.x86_64.rpm -y
yum localinstall /root/nginx-module-modsecurity-$nginx_version-$release_nginx.el$system_version.x86_64.rpm -y
yum localinstall  /root/libmaxminddb-1.7.1-1.el$system_version.x86_64.rpm -y

yum localinstall  /root/*.rpm -y
rpm -Uvh  /root/*.rpm 
rm -rf /root/*.rpm




yum install geolite2-city -y
yum -y install geolite2-country


#cd /etc/nginx/
#https://scripts.tino.org/dhparam.pem

openssl dhparam 2048 -out /etc/nginx/dhparam.pem
server_ip=$(dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com | sed -e 's/\"//g')
CREATE_STARTUP_SCRIPT_NGX
mkdir -p /etc/nginx/conf.d/

cd /etc/nginx/conf.d/

wget --no-check-certificate https://scripts.tino.org/tino-master.zip
echo "A" | unzip tino-master*
rm -rf tino-master.zip

cat > "/etc/nginx/conf.d/vhosts/phpmyadmin.conf" <<END
upstream netdata {
server 127.0.0.1:19999;
keepalive 64;
}
server {
	listen $admin_port default_server;
	listen 80;
	server_name _;
	root /opt/tinopanel/private_html;
	access_log /var/log/nginx/default-access_log;
	error_log /var/log/nginx/default-error_log warn;
 #   modsecurity on;
 #   modsecurity_rules_file /etc/nginx/modsec/main.conf;
    satisfy any;
    allow 127.0.0.1;
    deny all;
 
	auth_basic "Restricted";
	auth_basic_user_file /opt/tinopanel/ssl/.htpasswd;
	if (\$bad_bot) { return 444; }
	
	server_name_in_redirect off;

	#include conf.d/custom/restrictions.conf;
	#include conf.d/custom/pagespeed.conf;


  location /vts_status {
    vhost_traffic_status_bypass_limit on;
    vhost_traffic_status_bypass_stats on;
    vhost_traffic_status_display;
    vhost_traffic_status_display_format html;
  }
	
	location /stub_status {
	stub_status;
	allow 127.0.0.1;	#only allow requests from localhost
	deny all;
	}
	 
	location /nginx_status {
        stub_status on;
        access_log off;
        include conf.d/custom/admin-ips.conf; deny all;
    } 
      location /netdata {
        return 301 /netdata/;
   }

   location ~ /netdata/(?<ndpath>.*) {
        proxy_redirect off;
        proxy_set_header Host \$host;

        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Server \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_http_version 1.1;
        proxy_pass_request_headers on;
        proxy_set_header Connection "keep-alive";
        proxy_store off;
        proxy_pass http://netdata/\$ndpath\$is_args\$args;

    }


    location ~ ^/(status|ping)\$ {
	fastcgi_pass php; 
       access_log off;
    }
    	include conf.d/custom/fpm-default.conf;
}
END


mkdir -p /etc/nginx/conf.d/addon_confs
mkdir -p /etc/nginx/conf.d/ssl

systemctl start nginx.service
systemctl enable nginx.service


# vhost nginx
mkdir -p /opt/tinopanel
mkdir -p /opt/tinopanel/logs
mkdir -p /opt/tinopanel/private_html
mkdir -p /opt/tinopanel/ssl
cd /opt/tinopanel/ssl
server_name = "tinopanel"
admin_password=$(gen_pass)
cd /etc/nginx/

#wget --no-check-certificate https://scripts.tino.org/dhparam.pem


openssl dhparam -out /etc/nginx/dhparam.pem 2048
openssl genrsa -out server.key 2048
openssl rsa -in server.key -out server.key
openssl req -sha256 -new -key server.key -out server.csr -subj '/CN=localhost'
openssl x509 -req -sha256 -days 3650 -in server.csr -signkey server.key -out server.crt
printf "admin:$(openssl passwd -apr1 $admin_password)\n" > /opt/tinopanel/ssl/.htpasswd
ulimit -n 524288

arch=`uname -m`
if [ "$arch" = "x86_64" ]; then
XXX=amd64
else
XXX=x86
fi

service nginx restart

yum remove mariadb* -y

curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash -s -- --mariadb-server-version="mariadb-10.6"
yum install mariadb-server mariadb-client -y
yum update -y

yum install MariaDB-server MariaDB-client -y
systemctl start mariadb.service
systemctl enable  mariadb.service
## config mariadb
cp /etc/my.cnf /etc/my.cnf-original
cat > "/etc/my.cnf" <<END
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
local-infile=0
innodb_file_per_table
max-connections=200
tmp_table_size = 128M
max_heap_table_size = 128M
myisam_sort_buffer_size = 64M
join_buffer_size = 64M
thread_cache_size = 50
table_open_cache = 100
wait_timeout = 120
interactive_timeout = 120
sql-mode="NO_ENGINE_SUBSTITUTION"
bind-address=0.0.0.0
END
root_password=$(gen_pass)

#'/usr/bin/mysqladmin' -u root password "$root_password"
#mysql -u root -p"$root_password" -e "DROP DATABASE test"
#mysql -u root -p"$root_password" -e "FLUSH PRIVILEGES"

mysql -u root -p"$root_password" << EOF
ALTER USER root@localhost IDENTIFIED VIA mysql_native_password USING PASSWORD("$root_password");
use mysql;
flush privileges;
EOF

cat > "/root/.my.cnf" <<END
[client]
user=root
password=$root_password
END

chmod 600 /root/.my.cnf
systemctl stop mariadb.service
systemctl restart mariadb.service

mysqladmin drop test -f


## 
mkdir -p /etc/quicklemp/menu
cd /etc/quicklemp/menu
wget --no-check-certificate http://scripts.tino.org/menu.zip
unzip menu.zip
rm -rf menu.zip
chmod +x /etc/quicklemp/menu/*

cd /etc/quicklemp/
find ./* -type f -exec chmod +x {} \; 
cd /etc/quicklemp/menu
mv tino /usr/bin/

## install csf

systemctl mask firewalld
systemctl stop firewalld

yum install perl-libwww-perl -y
cd /tmp
wget --no-check-certificate https://download.configserver.com/csf.tgz
tar -xzf csf.tgz
cd csf
sh install.sh
sed -i 's/TESTING = "1"/TESTING = "0"/g' /etc/csf/csf.conf
sed -i 's/LF_SSHD = "5"/LF_SSHD = "10"/g' /etc/csf/csf.conf
sed -i 's/RESTRICT_SYSLOG = "0"/RESTRICT_SYSLOG = "1"/g' /etc/csf/csf.conf
sed -i 's/ICMP_IN_RATE = "1\/s/ICMP_IN_RATE = "0/g' /etc/csf/csf.conf
sed -i 's/TCP_OUT = "20,21,22,25,53,80,110,113,443,/TCP_OUT = "20,21,22,25,53,80,110,113,443,465,/g' /etc/csf/csf.conf

yum -y install e2fsprogs
yum install iptables perl-libwww-perl.noarch perl-LWP-Protocol-https.noarch perl-GDGraph wget tar perl-Math-BigInt -y


systemctl enable csf.service
cp /etc/csf/csf.conf /etc/csf/csf.conf.default.bak
add_port="7979,3306"

TCP_IN=$(cat /etc/csf/csf.conf | grep "TCP_IN = "| grep $add_port|sort | uniq | xargs -L1 | cut -f10 -d "" | awk '{print $NF}'  FS=,)
TCP_OUT=$(cat /etc/csf/csf.conf | grep 'TCP_OUT = '| grep $add_port|sort | uniq | xargs -L1 | cut -f10 -d "" | awk '{print $NF}'  FS=,)
UDP_IN=$(cat /etc/csf/csf.conf | grep 'UDP_IN = '| grep $add_port|sort | uniq | xargs -L1 | cut -f10 -d "" | awk '{print $NF}'  FS=,)
UDP_OUT=$(cat /etc/csf/csf.conf | grep 'UDP_OUT = '| grep $add_port|sort | uniq | xargs -L1 | cut -f10 -d "" | awk '{print $NF}'  FS=,)

TCP_IN_1=$(cat /etc/csf/csf.conf | grep "TCP_IN = "|sort | uniq | xargs -L1 | cut -f4 -d "" | awk '{print $NF}')
TCP_OUT_1=$(cat /etc/csf/csf.conf | grep 'TCP_OUT = '|sort | uniq | xargs -L1 | cut -f4 -d "" | awk '{print $NF}')
UDP_IN_1=$(cat /etc/csf/csf.conf | grep 'UDP_IN = '|sort | uniq | xargs -L1 |  cut -f4 -d "" | awk '{print $NF}')
UDP_OUT_1=$(cat /etc/csf/csf.conf | grep 'UDP_OUT = '|sort | uniq | xargs -L1 |  cut -f4 -d "" | awk '{print $NF}')


TCP_IN_new="${TCP_IN_1},$add_port"
TCP_OUT_new="${TCP_OUT_1},$add_port"
UDP_IN_new="${UDP_IN_1},$add_port"
UDP_OUT_new="${UDP_OUT_1},$add_port"

sleep 3

##TCP_IN

sed -i "s%${TCP_IN_1}%${TCP_IN_new}%" /etc/csf/csf.conf &>/dev/null
sed -i "s%${TCP_OUT_1}%${TCP_OUT_new}%" /etc/csf/csf.conf &>/dev/null
sed -i "s%${UDP_IN_1}%${UDP_IN_new}%" /etc/csf/csf.conf &>/dev/null
sed -i "s%${UDP_OUT_1}%${UDP_OUT_new}%" /etc/csf/csf.conf &>/dev/null


csf -r
systemctl restart csf.service
##endcsf
mkdir -p /etc/quicklemp/domains
yum install bind-utils -y
sleep 5
my_ip=$(dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com | sed -e 's/\"//g')
cat > "/etc/quicklemp/port.txt" <<END
$admin_port
END
cat > "/etc/quicklemp/ip_install" <<END
$my_ip
END
## install rclone
curl https://rclone.org/install.sh | bash

# install acmesh
curl https://get.acme.sh | sh &> /dev/null
/root/.acme.sh/acme.sh --upgrade --auto-upgrade
echo ""

cat > "/opt/server_install_account" <<END
IP: $my_ip
Link Admin : http://$my_ip:$admin_port/phpmyadmin
port :$admin_port
user login panel: admin
admin pass $admin_password

root mysql pass:  $root_password
END
cat > "/etc/quicklemp/php_install" <<END
$php_version
END
cat > "/etc/quicklemp/tino_version" <<END
1.0.0
END

cat > "/etc/quicklemp/php_version_for_install" <<END
$php_74
$php_73
$php_72
$php_71
$php_70
$php_56
$php_55
$php_54
$php_53
END
cat > "/etc/resolv.conf" <<END
nameserver 8.8.8.8
nameserver 8.8.4.4
END

cat > "/etc/logrotate.d/nginx" <<END
/var/log/nginx/*log /home/*/logs/*log {
    create 0644 root root
    daily
    rotate 10
    missingok
    notifempty
    compress
    size=100M
    sharedscripts
    postrotate
    [ -f /var/run/nginx.pid ] && kill -USR1 \`cat /var/run/nginx.pid\`
    endscript
}
END


##goaccess
#yum -y install goaccess

#cat > "/lib/systemd/system/goaccess.service" <<END
#[Unit]
#Description= goaccess
#After=network.target

#[Service]
#Type=simple
#User=root
#Group=root
#ExecStart=/etc/quicklemp/menu/goaccess.sh
#ExecReload=/bin/kill -s HUP $MAINPID
#ExecStop=/bin/kill -s QUIT $MAINPID
#KillSignal=SIGINT
#TimeoutSec=30
#Restart=on-failure
#RestartSec=1

#[Install]
#WantedBy = multi-user.target
#END

#systemctl enable goaccess
#systemctl start goaccess



sed -e '/Subsystem/ s/^#*/#/' -i  /etc/ssh/sshd_config

yum install pure-ftpd -y >& /dev/null
cat > "/etc/pure-ftpd.conf" <<END
ChrootEveryone               yes
BrokenClientsCompatibility   no
MaxClientsNumber             50
Daemonize                    yes
MaxClientsPerIP              15
VerboseLog                   no
DisplayDotFiles              yes
AnonymousOnly                no
NoAnonymous                  yes
SyslogFacility               ftp
DontResolve                  yes
MaxIdleTime                  15
PureDB                       /etc/pureftpd.pdb
LimitRecursion               10000 8
AnonymousCanCreateDirs       no
MaxLoad                      4
PassivePortRange             35000 35999
AntiWarez                    yes
Umask                        133:022
MinUID                       99
AllowUserFXP                 yes
AllowAnonymousFXP            no
ProhibitDotFilesWrite        no
ProhibitDotFilesRead         no
AutoRename                   no
AnonymousCantUpload          no
AltLog                       stats:/var/log/pureftpd.log
PIDFile                      /run/pure-ftpd.pid
CallUploadScript             no
MaxDiskUsage                   99
CustomerProof                yes
END

cat > "/etc/ftpusers" <<END
root
daemon
bin
sys
adm
lp
uccp
nuucp
listen
nobody
noaccess
nobody4
END

service pure-ftpd start
systemctl enable pure-ftpd


sed -i "/Subsystem/d" /etc/ssh/sshd_config >& /dev/null
sed -i "/Match Group/d" /etc/ssh/sshd_config >& /dev/null
sed -i "/ChrootDirectory/d" /etc/ssh/sshd_config >& /dev/null
sed -i "/ForceCommand/d" /etc/ssh/sshd_config >& /dev/null
sed -i "/X11Forwarding no/d" /etc/ssh/sshd_config >& /dev/null
sed -i "/AllowTCPForwarding/d" /etc/ssh/sshd_config >& /dev/null
sed -i "/PasswordAuthentication/d" /etc/ssh/sshd_config >& /dev/null

groupadd tinosftp_users >& /dev/null

cat >> "/etc/ssh/sshd_config" <<END
Subsystem sftp internal-sftp
Match Group tinosftp_users
   ChrootDirectory %h
   ForceCommand internal-sftp
   X11Forwarding no
   AllowTCPForwarding no
   PasswordAuthentication yes
END



service sshd restart >& /dev/null



##wpcli
ln -sf /opt/php/php$sock_tino/bin/php /usr/bin/php
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar   ## Táº£i wp-cli.
#php wp-cli.phar --info   ## xÃ¡c nháº­n táº£i thÃ nh cÃ´ng.
chmod +x wp-cli.phar ## phÃ¢n quyá»n cho wp-cli
mv wp-cli.phar /usr/local/bin/wp    ## di chuyá»ƒn wp-cli thÃ nh thÆ° viá»‡n.



# phpMyAdmin
#mkdir /opt/tinopanel/private_html/phpmyadmin/
#cd /opt/tinopanel/private_html/phpmyadmin/
#wget --no-check-certificate -q https://files.phpmyadmin.net/phpMyAdmin/4.9.5/phpMyAdmin-4.9.5-english.zip
#unzip -q phpMyAdmin-4.9.5-english.zip
#mv -f phpMyAdmin-4.9.5-english/* .
#rm -rf phpMyAdmin-4.9.5-english*

#phpmyadmin

cd /opt/tinopanel/private_html/
wget --no-check-certificate -q https://scripts.tino.org/guimenu.zip
echo "A" | unzip guimenu.zip
rm -rf /opt/tinopanel/private_html/guimenu.zip
chown -R tinopanel:tinopanel /opt/tinopanel/private_html/


ethenet_card=$(ip -4 route get 8.8.8.8 | grep -oP "dev [^[:space:]]+ " | cut -d ' ' -f 2)
sed -i "s/eth0/$ethenet_card/" /opt/tinopanel/private_html/index.html


#netdata
wget -O /tmp/netdata-kickstart.sh https://my-netdata.io/kickstart.sh && sh /tmp/netdata-kickstart.sh --uninstall
wget -O /tmp/netdata-kickstart.sh https://my-netdata.io/kickstart.sh && sh /tmp/netdata-kickstart.sh --dont-wait

systemctl enable netdata
systemctl start netdata

cd /etc/netdata 2>/dev/null || cd /opt/netdata/etc/netdata

echo "q" | ./edit-config go.d/nginx.conf
sleep 5

cat >> "/etc/netdata/go.d/nginx.conf" <<END
  - name: local
    url: http://127.0.0.1:7979/basic_status

  - name: local
    url: http://localhost:7979/stub_status

  - name: local
    url: http://127.0.0.1:7979/stub_status

  - name: local
    url: http://127.0.0.1:7979/nginx_status

  - name: local
    url: http://127.0.0.1:7979/status
END


csf -x


cd /etc/quicklemp/domains/

echo ""
echo "TURN ON - AUTO ANTI DDOS LAYER 7 WHEN VPS BEING ATTACK... "
echo "Tu dong bat chong DDOS moi khi server bi tan cong... "

sleep 5


mkdir -p /etc/nginx/html
cd /etc/nginx/html

wget --no-check-certificate --backups=1 https://scripts.tino.org/tino-nginx/TEM/aes.min.js  &> /dev/null
wget --no-check-certificate  --backups=1 https://scripts.tino.org/tino-nginx/TEM/captcha.html  &> /dev/null

csf -x  &> /dev/null
yum install git jq whois -y  &> /dev/null
echo ""  >  /tmp/whitelistip.txt
whois -h whois.radb.net -- '-i origin AS32934' | grep ^route |awk '{ print $2";" }' >> /tmp/whitelistip.txt
#whois -h whois.radb.net -- '-i origin AS13335' | grep ^route |awk '{ print $2";" }' >> /tmp/whitelistip.txt
curl -s https://www.gstatic.com/ipranges/goog.json | grep Prefix |  awk -F \" '{print $4";"}' >> /tmp/whitelistip.txt
#cat /tmp/whitelistip.txt |sort -u > /etc/nginx/whitelistip.txt
sort -u /etc/nginx/whitelistip.txt  /tmp/whitelistip.txt | uniq > /tmp/merge
cat /tmp/merge > /etc/nginx/whitelistip.txt
rm -rf  /tmp/whitelistip.txt


for opt in `ls /etc/quicklemp/domains/`; do
{
echo "TURN ON BLOCK ATTACK DDOS LAYER 7 for $opt"
 
echo "yes" > /etc/quicklemp/domains/$opt/ddos-mitigation;
rm -rf /etc/nginx/conf.d/addon_confs/$opt/checkcookie.conf
cd /etc/nginx/conf.d/addon_confs/$opt/
wget https://scripts.tino.org/tino-nginx/SOURCES/checkcookie.conf &> /dev/null

cat > "/etc/nginx/conf.d/addon_confs/$opt/checkcookieload.conf" <<END
location = /captcha.html {
testcookie off;
    root /etc/nginx/html;
}

location = /aes.min.js {
testcookie off;
    gzip on;
    gzip_min_length 1000;
    gzip_types text/plain;
    root /etc/nginx/html;
}

END


echo "no" > /etc/quicklemp/domains/$opt/ddos-mitigation; &>/dev/null
sed -i '/testcookie\ /s/on/off/' /etc/nginx/conf.d/addon_confs/$opt/checkcookie.conf &>/dev/null

};
done;

#########################

mkdir -p /opt/antiddos

cat >  "/etc/systemd/system/antiddostino.service" <<END
[Unit]
 Description= ON - OFF anti DDOS Layer7
 
[Service]
 ExecStart=/opt/antiddos/checkload

[Install]
 WantedBy=default.target
 
END

cat > "/opt/antiddos/checkload" <<END
#!/bin/sh
while [ 1 -gt 0 ]
do
    num=\$(grep ^cpu\\scores /proc/cpuinfo | uniq |  awk '{print \$4}')
    num=$((num * 4))
    load=\$(cat /proc/loadavg |awk '{print \$1}'|cut -d "." -f1)
    
    if [ "\$load" -gt "\$num" ] && [ "\$load" -gt 10 ]; then
        /usr/sbin/migatedddos on;
        
        topnum=\$(cat /home/*/logs/access*_log | awk -v start="\$(date -d '30 minutes ago' +[%d/%b/%Y:%H:%M:%S])" -v end="\$(date +[%d/%b/%Y:%H:%M:%S])" '\$4 > start && \$4 < end' | awk '{ print \$1}' | sort | uniq -c | sort -nr | head -n 1 |  awk '{ print \$1}')
        topip=\$(cat /home/*/logs/access*_log | awk -v start="\$(date -d '30 minutes ago' +[%d/%b/%Y:%H:%M:%S])" -v end="\$(date +[%d/%b/%Y:%H:%M:%S])" '\$4 > start && \$4 < end' | awk '{ print \$1}' | sort | uniq -c | sort -nr | head -n 1 |  awk '{ print \$2}')
        
        if [ "\$topnum" -gt 3000 ]; then
            csf -d  "\$topip"
            echo "\$(date):\$topip:\$topnum"  >> /opt/antiddos/checkload.log
        else
            echo "\$(date)" >> /opt/antiddos/checkload.log
        fi
        
        sleep 900;
        /usr/sbin/migatedddos off;
    fi
    sleep 1;
done
END

cat >  "/usr/sbin/migatedddos" <<END
#!/bin/bash
value=\$1
if [ "\$value" == "on" ]
then
    sed -i '/testcookie\ /s/off/on/' /etc/nginx/conf.d/addon_confs/*/checkcookie.conf
    echo " migatedddos  has been enable from the vhost configuration!"

	
elif [ "\$value" == "off" ]
then
    sed -i '/testcookie\ /s/on/off/' /etc/nginx/conf.d/addon_confs/*/checkcookie.conf
    echo " migatedddos  has been disable from the vhost configuration!"
else
   echo 'Warning: Import the environment variable "on" or "off" to use!'
fi
/usr/sbin/nginx -s reload

#systemctl restart php-fpm-74.service

for D in /opt/php/*; do
	if [ -d "\${D}" ]; then #If a directory
		php=\${D##*/} # Domain name
		php_ver=\${php:3}
		php_full="php-fpm-\${php_ver}"
	
	echo "restart \$php"
	service php-fpm-\$php_ver restart
fi
done
rm -rf /var/lib/nginx/cache/fastcgi/*

END

chmod +x /etc/systemd/system/antiddostino.service
chmod +x /usr/sbin/migatedddos

systemctl enable antiddostino
systemctl start antiddostino


#########################


chmod +x /opt/antiddos/checkload
nginx -s reload

echo "on" > /etc/quicklemp/antiddos

echo "Turned on ddos-mitigation for ALL DOMAIN success.!"

csf -e

#######################
yum install monit -y  &>/dev/null
rm -rf /etc/monit.d/*
cat > "/etc/monit.d/logging" <<END
# log to monit.log
set logfile /var/log/monit.log
END

cat > "/etc/monit.d/disk" <<END
check device rootfs with path /
  if space usage > 98% then exec "/bin/bash -c '/usr/bin/find /var/log/messages-* /home/*/logs/access_*.gz /home/*/logs/error_*.gz -delete'"
END
cat > "/etc/monit.d/mysql" <<END
check process mysql with pidfile /var/lib/mysql/sv.pid
  start program = "/usr/bin/systemctl start mysql"
  stop program  = "/usr/bin/systemctl stop mysql"
  if 5 restarts within 5 cycles then timeout
END
cat > "/etc/monit.d/nginx" <<END
check process nginx with pidfile /var/run/nginx.pid
  start program = "/usr/bin/systemctl start nginx"
  stop program  = "/usr/bin/systemctl stop nginx"
END

systemctl restart monit  &>/dev/null
systemctl enable monit  &>/dev/null
#######################


if [ "$sock_tino" -lt 56 ]; then
  ln -s /opt/remi/php$sock_tino/root/etc /etc/opt/remi/php$sock_tino
  
fi

ln -s /etc/opt/remi/php$sock_tino/ /opt/php/
ln -s /etc/opt/remi/php$sock_tino/ /opt/php/php$sock_tino/etc
unlink /etc/opt/remi/php$sock_tino/php$sock_tino
ln -s /opt/remi/php$sock_tino/root/bin/ /opt/php/php$sock_tino/

mkdir -p /opt/php/php$sock_tino/var/
ln -sf /var/opt/remi/php$sock_tino/run /opt/php/php$sock_tino/var/


mkdir -p /opt/php/php$sock_tino/lib/
sleep 5

ln -sf /etc/opt/remi/php$sock_tino/php.ini /opt/php/php$sock_tino/lib/


rm -rf /root/tinovps-install
rm -rf /root/tino/

echo ""  > /var/spool/cron/root
echo '14 0 * * * "/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh" > /dev/null && service nginx restart' >> /var/spool/cron/root
cd /opt/tinopanel/private_html/phpmyadmin/
chown -R tinopanel:tinopanel ../phpmyadmin/
cd /opt/tinopanel/private_html/phpmyadmin/
echo "yes"|cp  config.sample.inc.php config.inc.php
cd /opt/tinopanel/private_html/phpmyadmin/
echo "yes"|cp  config.sample.inc.php config.inc.php
randomBlowfishSecret=$(openssl rand -base64 32)
sed -e "s|cfg\['blowfish_secret'\] = ''|cfg['blowfish_secret'] = '$randomBlowfishSecret'|" config.sample.inc.php > config.inc.php

sleep 20

cd /root/

wget --no-check-certificate https://github.com/rclone/rclone/releases/download/v1.55.1/rclone-v1.55.1-linux-amd64.zip
unzip rclone-*
\cp rclone-*-linux-amd64/rclone /usr/bin/
rm -rf rclone-*

echo "exe:/usr/sbin/nginx" >> /etc/csf/csf.pignore



echo ""
echo ""

echo "Link truy cap trang quan ly phpmyadmin: http://$my_ip:$admin_port/phpmyadmin"
echo "user:admin"
echo " admin pass:$admin_password"
echo ""
echo ""
echo "Tai khoan quan ly ban co the doc tai file: /opt/server_install_account"





reboot

#!/bin/bash
# @author: LÃ£ng Tá»­ CÃ´ Äá»™c
# @website:  https://tinohost.com, https://kienthuclinux.com
# @since: 2020
