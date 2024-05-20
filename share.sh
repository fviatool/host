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

echo "Server setup complete. Replace <client_public_key_placeholder> with actual client public key in wg0.conf."
