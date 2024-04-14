#!/bin/bash

# Kiểm tra xem người dùng có quyền root hay không
if [ "$(id -u)" -ne 0 ]; then
    echo "Cần chạy với quyền root. Hãy sử dụng sudo." >&2
    exit 1
fi

# Cập nhật gói và cài đặt Apache
sudo apt update
sudo apt install -y apache2

# Cài đặt PHP và các mô-đun cần thiết
sudo apt install -y php libapache2-mod-php php-mysql

# Khởi động lại Apache
sudo systemctl restart apache2

# Cài đặt MySQL và cấu hình bảo mật
sudo apt install -y mysql-server
sudo mysql_secure_installation

# Kiểm tra xem thư mục www đã tồn tại chưa, nếu chưa thì tạo mới
if [ ! -d "/var/www/html" ]; then
    sudo mkdir -p /var/www/html
fi

# Đặt quyền sở hữu cho thư mục www
sudo chown -R $USER:$USER /var/www/html

# Hiển thị thông báo sau khi cài đặt hoàn tất
echo "Cài đặt môi trường phát triển thành công."

# Kiểm tra cài đặt bằng cách tạo một tệp tin PHP
echo "<?php phpinfo(); ?>" > /var/www/html/info.php

# Hiển thị thông báo sau khi cài đặt hoàn tất
echo "Cài đặt Apache và PHP hoàn tất. Truy cập http://localhost/info.php để kiểm tra."
