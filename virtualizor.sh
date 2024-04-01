#!/bin/bash
clear

setenforce 0 >> /dev/null 2>&1

# Flush the IP Tables
#iptables -F >> /dev/null 2>&1
#iptables -P INPUT ACCEPT >> /dev/null 2>&1

FILEREPO=https://files.virtualizor.com
LOG=/root/virtualizor.log
mirror_url=files.softaculous.com

for i in $@
do
	if [[ $i == mirror_url* ]]; then
	IFS='=' read -ra tmp_array <<< "$i"
	mirror_url=${tmp_array[1]}/a/softaculous/files
	fi
done

#----------------------------------
# Detecting the Architecture
#----------------------------------
if ([ `uname -i` == x86_64 ] || [ `uname -i` == amd64 ] || [ `uname -m` == x86_64 ] || [ `uname -m` == amd64 ]); then
	ARCH=64
else
	ARCH=32
fi

echo "-----------------------------------------------"
echo " Welcome to Softaculous Virtualizor Installer"
echo "-----------------------------------------------"
echo "To monitor installation : tail -f /root/virtualizor.log"
echo " "


#----------------------------------
# Some checks before we proceed
#----------------------------------

# Gets Distro type.
if [ -d /etc/pve ]; then
	OS=Proxmox
	REL=$(/usr/bin/pveversion)
elif [ -f /etc/debian_version ]; then	
	OS_ACTUAL=$(lsb_release -i | cut -f2)
	OS=Ubuntu
	REL=$(cat /etc/issue)
elif [ -f /etc/redhat-release ]; then
	OS=redhat 
	REL=$(cat /etc/redhat-release)
else
	OS=$(uname -s)
	REL=$(uname -r)
fi

if [[ "$REL" == *"CentOS release 6"* ]]; then
        echo "Softaculous Virtualizor only supports CentOS 7 and CentOS 8, as Centos 6 is EOL and their repository is not available for package downloads."
        echo "Exiting installer"
        exit 1;
fi

if [ "$OS" = Ubuntu ] ; then

	# We dont need to check for Debian
	if [ "$OS_ACTUAL" = Ubuntu ] ; then
	
		VER=$(lsb_release -r | cut -f2)
		
		if  [ "$VER" != "12.04" -a "$VER" != "14.04" -a "$VER" != "16.04" -a "$VER" != "18.04" -a "$VER" != "20.04" -a "$VER" != "22.04" ]; then
			echo "Softaculous Virtualizor only supports Ubuntu 12.04 LTS, Ubuntu 14.04 LTS, Ubuntu 16.04 LTS, Ubuntu 18.04 LTS, Ubuntu 20.04 LTS and Ubuntu 22.04 LTS"
			echo "Exiting installer"
			exit 1;
		fi

		if ! [ -f /etc/default/grub ] ; then
			echo "Softaculous Virtualizor only supports GRUB 2 for Ubuntu based server"
			echo "Follow the Below guide to upgrade to grub2 :-"
			echo "https://help.ubuntu.com/community/Grub2/Upgrading"
			echo "Exiting installer"
			exit 1;
		fi
		
	fi
	
fi

theos="$(echo $REL | egrep -i '(cent|Scie|Red|Ubuntu|xen|Virtuozzo|pve-manager|Debian|AlmaLinux|Rocky)' )"

if [ "$?" -ne "0" ]; then
	echo "Softaculous Virtualizor can be installed only on CentOS, AlmaLinux, Rocky Linux, Redhat, Scientific Linux, Ubuntu, XenServer, Virtuozzo and Proxmox"
	echo "Exiting installer"
	exit 1;
fi

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
		echo "YUM wasnt found on the system. Please install YUM !"
		echo "Exiting installer"
		exit 1;
	fi
	
	wget --no-check-certificate https://mirror.softaculous.com/virtualizor/virtualizor.repo -O /etc/yum.repos.d/virtualizor.repo >> $LOG 2>&1

fi

#----------------------------------
# Fix for AlamLinux GPG key
# https://almalinux.org/blog/2023-12-20-almalinux-8-key-update/
#----------------------------------
is_alma="$(echo $REL | egrep -i '(AlmaLinux)' )"
if [ "$?" -eq "0" ]; then
	is_it_alma8=$(rpm -E %{rhel})
	if [ $is_it_alma8 -eq 8 ]; then
		is_valid_gpg=$(rpm -q gpg-pubkey-ced7258b-6525146f)
		#If the key is not same then we will need to import it
		if [ "$is_valid_gpg" != "gpg-pubkey-ced7258b-6525146f" ]; then
			rpm --import https://repo.almalinux.org/almalinux/RPM-GPG-KEY-AlmaLinux
		fi
	fi
fi

	fi
	
elif [ "$OS" = Proxmox  ] ; then
	apt-get update -y >> $LOG 2>&1
	
	if [ `echo $REL | grep -c "pve-manager/4" ` -gt 0 ] || [ `echo $REL | grep -c "pve-manager/5" ` -gt 0 ] ; then
        	apt-get install -y kpartx gcc openssl unzip make e2fs apt-get install -y kpartx gcc openssl unzip make e2fsprogs gperf genisoimage flex bison pkg-config libpcre3-dev libreadline-dev libxml2-dev ocaml libselinux1-dev libsepol1-dev libyajl-dev libmagic-dev tar wget >> $LOG 2>&1
fi

if [ `echo $REL | grep -c "pve-manager/8" ` -eq 0 ]; then
		wget http://download.proxmox.com/debian/dists/wheezy/pve-no-subscription/binary-amd64/libfuse-dev_2.9.2-4_amd64.deb >> $LOG 2>&1
		dpkg -i libfuse-dev_2.9.2-4_amd64.deb >> $LOG 2>&1
fi

fi

#–––––––––––––––––

Install PHP, MySQL, Web Server

#–––––––––––––––––
echo “2) Installing PHP, MySQL and Web Server”

Stop all the services of EMPS if they were there.

/usr/local/emps/bin/mysqlctl stop >> $LOG 2>&1
/usr/local/emps/bin/nginxctl stop >> $LOG 2>&1
/usr/local/emps/bin/fpmctl stop >> $LOG 2>&1

Remove the EMPS package

rm -rf /usr/local/emps/ >> $LOG 2>&1

The necessary folders

mkdir /usr/local/emps >> $LOG 2>&1
mkdir /usr/local/virtualizor >> $LOG 2>&1

#just check if the necessary symlink is there or not
el8_symlink=”$(echo $REL | egrep -i ‘(release 8)’)”
if [ “$?” -eq “0” ]; then
/bin/ln -s /usr/lib64/libnsl.so.2 /usr/lib64/libnsl.so.1
fi

echo “1) Installing PHP, MySQL and Web Server” >> $LOG 2>&1
wget –no-check-certificate  -N -O /usr/local/virtualizor/EMPS.tar.gz “https://$mirror_url/emps.php?latest=1&arch=$ARCH” >> $LOG 2>&1

Extract EMPS

tar -xvzf /usr/local/virtualizor/EMPS.tar.gz -C /usr/local/emps >> $LOG 2>&1
rm -rf /usr/local/virtualizor/EMPS.tar.gz >> $LOG 2>&1

#–––––––––––––––––

Download and Install Virtualizor

#–––––––––––––––––
echo “3) Downloading and Installing Virtualizor”
echo “3) Downloading and Installing Virtualizor” >> $LOG 2>&1

Get our installer

wget –no-check-certificate  -O /usr/local/virtualizor/install.php $FILEREPO/install.inc >> $LOG 2>&1
#echo “copying install file”
#mv install.inc /usr/local/virtualizor/install.php

Run our installer

/usr/local/emps/bin/php -d zend_extension=/usr/local/emps/lib/php/ioncube_loader_lin_5.3.so /usr/local/virtualizor/install.php $*
phpret=$?
rm -rf /usr/local/virtualizor/install.php >> $LOG 2>&1
rm -rf /usr/local/virtualizor/upgrade.php >> $LOG 2>&1

Was there an error

if ! [ $phpret == “8” ]; then
echo “ “
echo “ERROR :”
echo “There was an error while installing Virtualizor”
echo “Please check /root/virtualizor.log for errors”
echo “Exiting Installer”
exit 1;
fi

#–––––––––––––––––

Starting Virtualizor Services

#–––––––––––––––––
echo “Starting Virtualizor Services” >> $LOG 2>&1
/etc/init.d/virtualizor restart >> $LOG 2>&1

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
/usr/local/emps/bin/php -r ‘define(“VIRTUALIZOR”, 1); include(”/usr/local/virtualizor/universal.php”); echo “API KEY : “.$globals[“key”].”\nAPI Password : “.$globals[“pass”];’
echo “ “
echo “ “
echo “You can login to the Virtualizor Admin Panel”
echo “using your ROOT details at the followingURL :”
echo “https://$ip:4085/”
echo “OR”
echo “http://$ip:4084/”
echo “ “
echo “You will need to reboot this machine to load the correct kernel”
echo -n “Do you want to reboot now ? [y/N]”
read rebBOOT

echo “Thank you for choosing Softaculous Virtualizor !”

if ([ “$rebBOOT” == “Y” ] || [ “$rebBOOT” == “y” ]); then
echo “The system is now being RESTARTED”
reboot;
fi
