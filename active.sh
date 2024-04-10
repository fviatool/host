#!/bin/bash

# Sao lưu tệp cpanel.lisc
cp /usr/local/cpanel/cpanel.lisc /usr/local/cpanel/cpanel.lisc.backup

# Chỉnh quyền truy cập và thuộc tính của tệp
chmod 0444 /usr/local/cpanel/cpanel.lisc
chattr +i /usr/local/cpanel/cpanel.lisc

# Sửa thời gian hết hạn trong tệp cpanel.lisc thành năm 3000
sed -i 's/license_expire_time: [0-9]\+/license_expire_time: 32503680000/' /usr/local/cpanel/cpanel.lisc
