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

# Hiển thị thông báo hoàn thành
echo "Trang localhost đã được thiết lập thành công."
