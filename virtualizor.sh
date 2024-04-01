#!/bin/bash
clear

setenforce 0 >> /dev/null 2>&1

# Flush the IP Tables
#iptables -F >> /dev/null 2>&1
#iptables -P INPUT ACCEPT >> /dev/null 2>&1

FILEREPO=https://files.virtualizor.com
LOG=/root/virtualizor.log
mirror_url=files.softaculous.com

echo "-----------------------------------------------"
echo " Welcome to Softaculous Virtualizor Installer"
echo "-----------------------------------------------"
echo "To monitor installation : tail -f /root/virtualizor.log"
echo " "

#----------------------------------
# Detecting the Architecture
#----------------------------------
if ([ `uname -i` == x86_64 ] || [ `uname -i` == amd64 ] || [ `uname -m` == x86_64 ] || [ `uname -m` == amd64 ]); then
	ARCH=64
else
	ARCH=32
fi

#----------------------------------
# Some checks before we proceed
#----------------------------------
OS=$(uname -s)
REL=$(uname -r)

theos="$(echo $REL | egrep -i '(cent|Scie|Red|Ubuntu|xen|Virtuozzo|pve-manager|Debian|AlmaLinux|Rocky)' )"

# Is Webuzo installed ?
if [ -d /usr/local/webuzo ]; then
	echo "Server has webuzo installed. Virtualizor can not be installed."
	echo "Exiting installer"
	exit 1;
fi

#----------------------------------
# Is there an existing Virtualizor
#----------------------------------
if [ -d /usr/local/virtualizor ]; then
	echo "An existing installation of Virtualizor has been detected !"
	echo "If you continue to install Virtualizor, the existing installation"
	echo "and all its Data will be lost"
	echo -n "Do you want to continue installing ? [y/N]"
	
	read over_ride_install

	if ([ "$over_ride_install" == "N" ] || [ "$over_ride_install" == "n" ]); then	
		echo "Exiting Installer"
		exit;
	fi
fi

#----------------------------------
# Enabling Virtualizor repo
#----------------------------------
if [ "$OS" = redhat ] ; then
	# Is yum there ?
	if ! [ -f /usr/bin/yum ] ; then
		echo "YUM wasn't found on the system. Please install YUM !"
		echo "Exiting installer"
		exit 1;
	fi
	
	wget --no-check-certificate https://mirror.softaculous.com/virtualizor/virtualizor.repo -O /etc/yum.repos.d/virtualizor.repo >> $LOG 2>&1
fi

#----------------------------------
# Download and Install Virtualizor
#----------------------------------
echo "3) Downloading and Installing Virtualizor"
echo "3) Downloading and Installing Virtualizor" >> $LOG 2>&1

# Get our installer
wget --no-check-certificate  -O /usr/local/virtualizor/install.php $FILEREPO/install.inc >> $LOG 2>&1

# Run our installer
/usr/local/emps/bin/php -d zend_extension=/usr/local/emps/lib/php/ioncube_loader_lin_5.3.so /usr/local/virtualizor/install.php $*
phpret=$?
rm -rf /usr/local/virtualizor/install.php >> $LOG 2>&1
rm -rf /usr/local/virtualizor/upgrade.php >> $LOG 2>&1

# Was there an error
if ! [ $phpret == "8" ]; then
	echo " "
	echo "ERROR :"
	echo "There was an error while installing Virtualizor"
	echo "Please check /root/virtualizor.log for errors"
	echo "Exiting Installer"	
 	exit 1;
fi

#----------------------------------
# Starting Virtualizor Services
#----------------------------------
echo "Starting Virtualizor Services" >> $LOG 2>&1
/etc/init.d/virtualizor restart >> $LOG 2>&1

echo " "
echo "-------------------------------------"
echo " Installation Completed "
echo "-------------------------------------"

wget –no-check-certificate  -O /tmp/ip.php https://softaculous.com/ip.php >> $LOG 2>&1
ip=$(cat /tmp/ip.php)
rm -rf /tmp/ip.php

echo “ “
echo “———————————––”
echo “ Installation Completed “
echo “———————————––”
clear
echo “Congratulations, Virtualizor has been successfully installed”
echo “ “
/usr/local/emps/bin/php -r ’define(“VIRTUALIZOR”, 1);include(”/usr/local/virtualizor/universal.php”); echo “API KEY : “.$globals[“key”].”\nAPI Password : “.$globals[“pass”];’
echo “ “
echo “ “
echo “You can login to the Virtualizor Admin Panel”
echo “using your ROOT details at the following URL :”
echo “https://$ip:4085/”
echo “OR”
echo “http://$ip:4084/”
echo “ “
echo “You will need to reboot this machine to load the correct kernel”
echo -n “Do you want to reboot now ? [y/N]”
read rebBOOT

echo “Thank you for choosing Softaculous Virtualizor !”

if ([ “$rebBOOT” == “Y” ] || [ “$rebBOOT” == “y” ]); thenecho “The system is now being RESTARTED”
reboot;
fi
