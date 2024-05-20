#!/bin/bash

# Cài đặt Docker
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y docker-ce

# Khởi động Docker
sudo systemctl start docker
sudo systemctl enable docker

# Cài đặt WireGuard
sudo apt install -y wireguard

# Tạo cặp khóa WireGuard cho máy chủ
sudo mkdir -p /etc/wireguard
cd /etc/wireguard || exit
wg genkey | sudo tee server_private.key | wg pubkey | sudo tee server_public.key

# Tạo tệp cấu hình WireGuard cho máy chủ
SERVER_PRIVATE_KEY=$(cat /etc/wireguard/server_private.key)
CLIENT_PUBLIC_KEY="<client_public_key_placeholder>"

cat <<EOF | sudo tee /etc/wireguard/wg0.conf
[Interface]
Address = 10.0.0.1/24
SaveConfig = true
PrivateKey = $SERVER_PRIVATE_KEY
ListenPort = 51820

[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = 10.0.0.2/32
EOF

# Khởi động và kích hoạt WireGuard trên máy chủ
sudo systemctl start [email protected]
sudo systemctl enable [email protected]

# Mở cổng tường lửa
sudo ufw allow 51820/udp

# Bật tính năng chuyển tiếp IP
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Define the directory and file paths
cpanel_directory="/usr/local/cpanel"
license_file="cpanel.lisc"
key_file="cpkeyclt"

# Define the directory path to WireGuard and the configuration file
wireguard_directory="/etc/wireguard"
key_path="$wireguard_directory/cpanel_key.txt"

# Read the key from the cpkeyclt file and copy it to the WireGuard directory
if [ -f "$cpanel_directory/$key_file" ]; then
    cp "$cpanel_directory/$key_file" "$key_path"
    echo "Successfully copied key from $key_file to WireGuard directory."
else
    echo "Error: $key_file does not exist."
    exit 1
fi

# Check connection from the client and perform necessary actions
client_ip="10.0.0.2"
if ping -c 1 "$client_ip" &> /dev/null; then
    # Perform actions when there is a connection from the client
    echo "Key đã được gửi đến máy con."
    # Add other actions if needed
else
    echo "Không thể kết nối tới máy con với địa chỉ IP: $client_ip."
fi

# Kiểm tra cấu hình WireGuard
echo "Checking WireGuard configuration..."
sudo wg show

# Kiểm tra các container Docker đang chạy
echo "Checking running Docker containers..."
sudo docker ps

# Kiểm tra kết nối VPN tới máy con
echo "Checking VPN connection to client..."
ping -c 4 10.0.0.2

# Xóa script sau khi hoàn thành (nếu cần)
# rm -fr share.sh
