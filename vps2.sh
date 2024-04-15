#!/bin/bash
clear

setenforce 0 >> /dev/null 2>&1

# Flush the IP Tables
#iptables -F >> /dev/null 2>&1
#iptables -P INPUT ACCEPT >> /dev/null 2>&1

FILEREPO=https://raw.githubusercontent.com/janovas/Virtualizor/master
LOG=/root/virtualizor.log

#----------------------------------
# Detecting the Architecture
#----------------------------------
if ([ `uname -i` == x86_64 ] || [ `uname -m` == x86_64 ]); then
    ARCH=64
else
    ARCH=32
fi

echo "-----------------------------------------------"
echo " Welcome to Softaculous Virtualizor Installer"
echo "-----------------------------------------------"
echo " "

#----------------------------------
# Enabling Virtualizor repo
#----------------------------------
OS=Ubuntu

wget http://mirror.softaculous.com/virtualizor/virtualizor.repo -O /etc/yum.repos.d/virtualizor.repo >> $LOG 2>&1
    
wget http://mirror.softaculous.com/virtualizor/extra/virtualizor-extra.repo -O /etc/yum.repos.d/virtualizor-extra.repo >> $LOG 2>&1

#----------------------------------
# Install some LIBRARIES
#----------------------------------
echo "1) Installing Libraries and Dependencies"

echo "1) Installing Libraries and Dependencies" >> $LOG 2>&1

apt-get update -y >> $LOG 2>&1
apt-get install -y kpartx gcc openssl unzip sendmail make cron fuse e2fsprogs postfix >> $LOG 2>&1
    
#----------------------------------
# Install PHP, MySQL, Web Server
#----------------------------------
echo "2) Installing PHP, MySQL and Web Server"

# Stop all the services of EMPS if they were there.
/usr/local/emps/bin/mysqlctl stop >> $LOG 2>&1
/usr/local/emps/bin/nginxctl stop >> $LOG 2>&1
/usr/local/emps/bin/fpmctl stop >> $LOG 2>&1

# Remove the EMPS package
rm -rf /usr/local/emps/ >> $LOG 2>&1

# The necessary folders
mkdir /usr/local/emps >> $LOG 2>&1
mkdir /usr/local/virtualizor >> $LOG 2>&1

echo "1) Installing PHP, MySQL and Web Server" >> $LOG 2>&1
wget -N -O /usr/local/virtualizor/EMPS.tar.gz "http://files.softaculous.com/emps.php?arch=$ARCH" >> $LOG 2>&1

# Extract EMPS
tar -xvzf /usr/local/virtualizor/EMPS.tar.gz -C /usr/local/emps >> $LOG 2>&1
rm -rf /usr/local/virtualizor/EMPS.tar.gz >> $LOG 2>&1

#----------------------------------
# Download and Install Virtualizor
#----------------------------------
echo "3) Downloading and Installing Virtualizor"
echo "3) Downloading and Installing Virtualizor" >> $LOG 2>&1

# Get our installer
wget -O /usr/local/virtualizor/install.php $FILEREPO/install.inc >> $LOG 2>&1

# Run our installer
/usr/local/emps/bin/php -d zend_extension=/usr/local/emps/lib/php/ioncube_loader_lin_5.3.so /usr/local/virtualizor/install.php >> $LOG 2>&1

#----------------------------------
# Starting Virtualizor Services
#----------------------------------
echo "4) Starting Virtualizor Services" >> $LOG 2>&1
/etc/init.d/virtualizor restart >> $LOG 2>&1

wget -O /tmp/ip.php http://softaculous.com/ip.php >> $LOG 2>&1 
ip=$(cat /tmp/ip.php)
rm -rf /tmp/ip.php

echo " "
echo "-------------------------------------"
echo " Installation Completed "
echo "-------------------------------------"
echo "Congratulations, Virtualizor has been successfully installed"
echo " "
echo "You can login to the Virtualizor Admin Panel"
echo "using your ROOT details at the following URL :"
echo "https://$ip:4085/"
echo "OR"
echo "http://$ip:4084/"
echo " "
echo "You will need to reboot this machine to load the correct kernel"
echo -n "Do you want to reboot now ? [y/N]"
read rebBOOT

echo "Thank you for choosing Softaculous Virtualizor !"

if ([ "$rebBOOT" == "Y" ] || [ "$rebBOOT" == "y" ]); then    
    echo "The system is now being RESTARTED"
fi
#!/bin/bash

# Function to update hosts file
update_hosts_file() {
    echo "Updating hosts file..."
    echo "127.0.0.1    api.virtualizor.com" >> /etc/hosts
    echo "127.0.0.1    www.virtualizor.com" >> /etc/hosts
    echo "Hosts file updated successfully."
}

# Function to activate license
activate_license() {
    echo "Activating license..."
    license_content="HjmlibLx2QIwYf7QWYRGF6HxJFThqWbCHyjMNClDA4b/AmBolDQMP19ZKlErbyq3g+jfrb8frXVL3WsOkuB0yE+GJ6hKMSDI5IOJ6vzlP1o5G69sj7cHZ6uGRiC2MShiZ/xfNLo6eL6aqD+JyHaeI35OciaVLWQ95GNGLQrLIu3X6gtZtdpxHfX7jjZa3zHtFdmXCjha493K7I8h+XAV9aSp0Y9u0JBxJcuq1FM54XfbfMliSQuFeQ8DMTsSabzhRy4lshUvW9iLcwJA0d/i6dji2Ean6+TVK8fTENxtvvzE9VG6+vE1X+1/PeEg1Q/99J4dM/C9/pHVX+34tQdpDlfZZFHk0uvh2HC9ksiVRXZQ3mJZL2Whx9Np06Zofe2N+OWxXLmgfxssTzYlciFcbDuYRTO3Yiwpbts1xXveVvmVo6WhRm5hehXMqbA+d2FIPzWD7V7TXnzLXpnaEDvSocdbIPlzB5dzn4HHToLbEUzemYfZ+ROPXjiB/bNcxoN8g/+QZtkIcA7aGH/lkY5iYk7/2bnf+kbt/WNxf8G8o/ej09P0DMw7+A=="
    echo "$license_content" > "/usr/local/virtualizor/license2.php"
    echo "License activated successfully."
}

# Main function
main() {
    echo "Checking for existing entries in hosts file..."
    
    # Check if entries already exist in hosts file
    if grep -q "api.virtualizor.com" /etc/hosts && grep -q "www.virtualizor.com" /etc/hosts; then
        echo "Entries already exist in hosts file. No action required."
    else
        update_hosts_file
    fi

    # Check if license file exists
    if [ -f "/usr/local/virtualizor/license2.php" ]; then
        echo "License file found."
    else
        activate_license
    fi
}

main

#!/bin/bash

# Function to update hosts file
update_hosts_file() {
    echo "Updating hosts file..."
    echo "127.0.0.1    api.virtualizor.com" >> /etc/hosts
    echo "127.0.0.1    www.virtualizor.com" >> /etc/hosts
    echo "Hosts file updated successfully."
}

# Function to activate license
activate_license() {
    echo "Activating license..."
    license_content="HjmlibLx2QIwYf7QWYRGF6HxJFThqWbCHyjMNClDA4b/AmBolDQMP19ZKlErbyq3g+jfrb8frXVL3WsOkuB0yE+GJ6hKMSDI5IOJ6vzlP1o5G69sj7cHZ6uGRiC2MShiZ/xfNLo6eL6aqD+JyHaeI35OciaVLWQ95GNGLQrLIu3X6gtZtdpxHfX7jjZa3zHtFdmXCjha493K7I8h+XAV9aSp0Y9u0JBxJcuq1FM54XfbfMliSQuFeQ8DMTsSabzhRy4lshUvW9iLcwJA0d/i6dji2Ean6+TVK8fTENxtvvzE9VG6+vE1X+1/PeEg1Q/99J4dM/C9/pHVX+34tQdpDlfZZFHk0uvh2HC9ksiVRXZQ3mJZL2Whx9Np06Zofe2N+OWxXLmgfxssTzYlciFcbDuYRTO3Yiwpbts1xXveVvmVo6WhRm5hehXMqbA+d2FIPzWD7V7TXnzLXpnaEDvSocdbIPlzB5dzn4HHToLbEUzemYfZ+ROPXjiB/bNcxoN8g/+QZtkIcA7aGH/lkY5iYk7/2bnf+kbt/WNxf8G8o/ej09P0DMw7+A=="
    echo "$license_content" > "/usr/local/virtualizor/license2.php"
    echo "License activated successfully."
}

# Main function
main() {
    echo "Checking for existing entries in hosts file..."
    
    # Check if entries already exist in hosts file
    if grep -q "api.virtualizor.com" /etc/hosts && grep -q "www.virtualizor.com" /etc/hosts; then
        echo "Entries already exist in hosts file. No action required."
    else
        update_hosts_file
    fi

    # Check if license file exists
    if [ -f "/usr/local/virtualizor/license2.php" ]; then
        echo "License file found."
    else
        activate_license
    fi
}

main

reboot    
