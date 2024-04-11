#!/bin/bash

# Đường dẫn tới tập tin nhật ký
LOG_FILE="/var/log/install_cockpit.log"

# Hàm ghi log
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

# Kiểm tra xem người dùng có quyền sudo không
if [ "$EUID" -ne 0 ]; then
    echo "Hãy chạy script này với quyền root hoặc sudo." 
    exit 1
fi

# Kiểm tra phiên bản của hệ điều hành
os_version=$(cat /etc/os-release | grep '^VERSION_ID' | cut -d '"' -f 2)
log "Phiên bản hệ thống: $os_version"

# Cập nhật hệ thống
log "Đang cập nhật hệ thống..."
yum update -y >> "$LOG_FILE" 2>&1 || { log "Lỗi khi cập nhật hệ thống"; exit 1; }
log "Cập nhật hệ thống thành công."

# Cài đặt Cockpit
log "Đang cài đặt Cockpit..."
yum install cockpit -y >> "$LOG_FILE" 2>&1 || { log "Lỗi khi cài đặt Cockpit"; exit 1; }
log "Cài đặt Cockpit thành công."

# Bật và kích hoạt Cockpit
log "Bật và kích hoạt Cockpit..."
systemctl start cockpit >> "$LOG_FILE" 2>&1 || { log "Lỗi khi bật Cockpit"; exit 1; }
systemctl enable cockpit.socket >> "$LOG_FILE" 2>&1 || { log "Lỗi khi kích hoạt Cockpit"; exit 1; }
log "Cockpit đã được bật và kích hoạt."

# Mở cổng 9090 trong firewall
log "Mở cổng 9090 trong firewall..."
firewall-cmd --zone=public --add-port=9090/tcp --permanent >> "$LOG_FILE" 2>&1 || { log "Lỗi khi mở cổng firewall"; exit 1; }
firewall-cmd --reload >> "$LOG_FILE" 2>&1 || { log "Lỗi khi tải lại cấu hình firewall"; exit 1; }
log "Cổng 9090 đã được mở trong firewall."

# Hiển thị thông báo hoàn tất và đường dẫn đến tệp nhật ký
echo "Cài đặt và kích hoạt Cockpit đã hoàn tất! Xem log tại $LOG_FILE"
