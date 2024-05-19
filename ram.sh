#!/bin/bash

# Kích thước swap mong muốn (có thể thay đổi theo nhu cầu của bạn)
SWAP_SIZE="2G"

# Kiểm tra xem swap đã tồn tại chưa
if sudo swapon --show | grep -q '/swapfile'; then
  echo "Swap đã được cấu hình và đang hoạt động."
  exit 0
fi

# Tạo tệp swap với kích thước đã định
echo "Tạo tệp swap với kích thước $SWAP_SIZE..."
sudo fallocate -l $SWAP_SIZE /swapfile || sudo dd if=/dev/zero of=/swapfile bs=1M count=$((${SWAP_SIZE%G} * 1024))

# Thiết lập quyền truy cập cho tệp swap
echo "Thiết lập quyền truy cập cho tệp swap..."
sudo chmod 600 /swapfile

# Định dạng tệp swap
echo "Định dạng tệp swap..."
sudo mkswap /swapfile

# Kích hoạt tệp swap
echo "Kích hoạt tệp swap..."
sudo swapon /swapfile

# Kiểm tra lại swap
echo "Kiểm tra lại swap..."
sudo swapon --show
free -h

# Thêm tệp swap vào /etc/fstab để tự động kích hoạt sau khi khởi động lại
echo "Cấu hình swap để tự động kích hoạt sau khi khởi động lại..."
sudo cp /etc/fstab /etc/fstab.bak
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Tùy chọn: Điều chỉnh vm.swappiness (có thể thay đổi theo nhu cầu của bạn)
SWAPPINESS=10
echo "Điều chỉnh vm.swappiness thành $SWAPPINESS..."
sudo sysctl vm.swappiness=$SWAPPINESS
echo "vm.swappiness=$SWAPPINESS" | sudo tee -a /etc/sysctl.conf

echo "Cấu hình swap hoàn tất."
