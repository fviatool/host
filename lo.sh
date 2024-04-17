#!/bin/bash

# Cài đặt Apache
sudo yum install -y httpd

# Khởi động dịch vụ Apache
sudo systemctl start httpd

# Kích hoạt Apache để tự động khởi động khi khởi động hệ thống
sudo systemctl enable httpd

# Tạo thư mục cho trang localhost
sudo mkdir -p /var/www/html

# Upload các tệp và thư mục của trang web vào thư mục /var/www/html

# Tạo file cấu hình Virtual Host mặc định
sudo tee /etc/httpd/conf.d/localhost.conf <<EOF
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html
    ErrorLog /var/log/httpd/error_log
    CustomLog /var/log/httpd/access_log combined
</VirtualHost>
EOF

# Kiểm tra cấu hình Apache
sudo apachectl configtest

# Nếu không có lỗi, khởi động lại dịch vụ Apache
sudo systemctl restart httpd
sudo yum install -y epel-release yum-utils
sudo yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm
sudo yum-config-manager --enable remi-php74
sudo yum install -y php php-common php-cli php-fpm php-mysqlnd php-zip php-devel php-gd php-mcrypt php-mbstring php-curl php-xml php-pear php-bcmath php-json

# Cài đặt gói IMAP cho PHP
sudo yum install -y php-imap

# Khởi động lại Apache để áp dụng các thay đổi
sudo systemctl restart httpd
# Hiển thị thông báo hoàn thành
echo "Trang localhost đã được thiết lập thành công."
