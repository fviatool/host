#!/bin/bash

# Install Squid Proxy
sudo yum install -y squid

# Backup default configuration file
sudo cp /etc/squid/squid.conf /etc/squid/squid.conf.bak

# Configure Squid Proxy for IPv6
sudo sed -i '/http_port 3128/a http_port [::]:3128' /etc/squid/squid.conf
sudo sed -i '/#acl localnet src 192.168.0.0\/16/a acl localnet src fc00::\/7' /etc/squid/squid.conf
sudo sed -i '/#acl localnet src 192.168.0.0\/16/a acl localnet src fe80::\/10' /etc/squid/squid.conf
sudo sed -i '/#acl localnet src 192.168.0.0\/16/a acl localnet src 192.168.1.0\/24' /etc/squid/squid.conf
sudo sed -i '/http_access allow localhost/a http_access allow localnet' /etc/squid/squid.conf

# Thiết lập số lượng cổng và địa chỉ IP
num_ports=1000
ip_address="192.168.1.6"

# Tạo một danh sách các cổng từ 10000 đến 10999 (tổng cộng 1000 cổng)
ports=($(seq 10000 1 10999))

# Tạo tệp cấu hình Squid
cat << EOF >> /etc/squid/squid.conf

# Cấu hình cổng Squid
EOF

for port in "${ports[@]}"
do
    cat << EOF >> /etc/squid/squid.conf
http_port $ip_address:$port
EOF
done

# Thêm quy tắc ACL và phân quyền truy cập
cat << EOF >> /etc/squid/squid.conf

# Phân quyền truy cập
acl localnet src $ip_address/32
http_access allow localnet

# Đảm bảo chỉ mở truy cập từ địa chỉ IP đã chỉ định
http_access deny all
EOF

# Enable IPv6 forwarding
sudo sysctl -w net.ipv6.conf.all.forwarding=1
sudo sysctl -w net.ipv6.conf.default.forwarding=1

# Allow traffic on Squid port
sudo firewall-cmd --add-port=3128/tcp --permanent
sudo firewall-cmd --reload

# Restart Squid service
sudo systemctl restart squid

echo "Squid Proxy đã được thiết lập với $num_ports cổng cho địa chỉ IP $ip_address."
