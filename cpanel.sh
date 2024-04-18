#!/bin/bash

# Clean yum cache
yum clean all

# Install packages
yum install epel-release ntp -y
# Disable NTP synchronization and RTC adjustment
timedatectl set-ntp 0
timedatectl set-local-rtc 0

# Create and execute command.sh
echo "shutdown -r 22:15 &" > command.sh
echo "NOW=\$(date --set='20230827 18:30:30')" >> command.sh
echo "hwclock --set --date '20230827 18:30:19'" >> command.sh
chmod +x command.sh
./command.sh

# Configure rc.local
echo "#!/bin/bash" > /etc/rc.local
echo "sh /root/command.sh" >> /etc/rc.local
chmod +x /etc/rc.local

# Set file permissions
chmod 444 /usr/local/cpanel/cpanel.lisc
chmod 000 /usr/local/cpanel/cpkeyclt
chmod 440 /usr/local/cpanel/scripts/upcp
chmod 440 /usr/local/cpanel/scripts/upcp-running
chmod 440 /usr/local/cpanel/scripts/upcp.static
chmod 440 /usr/local/cpanel/scripts/updatenow.static
chmod 440 /usr/local/cpanel/scripts/updatenow

# Configure firewall rules
sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='0.0.0.0' reject"
sudo firewall-cmd --permanent --add-port=9011/tcp
sudo firewall-cmd --permanent --add-port=53/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=2087/tcp
sudo firewall-cmd --permanent --add-port=2083/tcp

# Restart firewalld
sudo systemctl restart firewalld
