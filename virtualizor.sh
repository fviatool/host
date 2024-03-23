#!/bin/bash

# Virtualizor v1 System
version="1"

# Function to delete old license key and update with new key
update_license_key() {
    echo "Đang xóa mã bản quyền cũ..."
    rm /usr/local/virtualizor/license2.php
    echo "Cập nhật bằng mã bản quyền mới..."
    lic="HjmlibLx2QIwYf7QWYRGF6HxJFThqWbCHyjMNClDA4b/AmBolDQMP19ZKlErbyq3g+jfrb8frXVL3WsOkuB0yE+GJ6hKMSDI5IOJ6vzlP1o5G69sj7cHZ6uGRiC2MShiZ/xfNLo6eL6aqD+JyHaeI35OciaVLWQ95GNGLQrLIu3X6gtZtdpxHfX7jjZa3zHtFdmXCjha493K7I8h+XAV9aSp0Y9u0JBxJcuq1FM54XfbfMliSQuFeQ8DMTsSabzhRy4lshUvW9iLcwJA0d/i6dji2Ean6+TVK8fTENxtvvzE9VG6+vE1X+1/PeEg1Q/99J4dM/C9/pHVX+34tQdpDlfZZFHk0uvh2HC9ksiVRXZQ3mJZL2Whx9Np06Zofe2N+OWxXLmgfxssTzYlciFcbDuYRTO3Yiwpbts1xXveVvmVo6WhRm5hehXMqbA+d2FIPzWD7V7TXnzLXpnaEDvSocdbIPlzB5dzn4HHToLbEUzemYfZ+ROPXjiB/bNcxoN8g/+QZtkIcA7aGH/lkY5iYk7/2bnf+kbt/WNxf8G8o/ej09P0DMw7+A=="
    echo "$lic" > /usr/local/virtualizor/license2.php
    echo "Cập nhật mã bản quyền thành công."
}

# Function to update hosts file
update_hosts_file() {
    echo "Đang cập nhật file hosts..."
    echo "127.0.0.1               api.virtualizor.com" >> /etc/hosts
    echo "127.0.0.1               www.virtualizor.com" >> /etc/hosts
    echo "Cập nhật file hosts thành công."
}

# Main function
main() Menu Virtualizor {
    while true; do
        echo "1. Xóa mã bản quyền cũ và cập nhật bằng mã mới"
        echo "2. Cập nhật file hosts"
        echo "0. Thoát"
        echo "Nhập lựa chọn của bạn: "
        read choice

        case $choice in
            0)
                echo "Thoát..."
                exit 0
                ;;
            1)
                update_license_key
                ;;
            2)
                update_hosts_file
                ;;
            *)
                echo "Lựa chọn không hợp lệ. Vui lòng thử lại."
                ;;
        esac
    done
}

# Call the main function
main
