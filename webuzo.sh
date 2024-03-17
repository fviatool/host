#!/bin/bash
clear

no_lamp_check=0

for ARGUMENT in "$@"
do
	KEY=$(echo $ARGUMENT | cut -f1 -d=)
	VALUE=$(echo $ARGUMENT | cut -f2 -d=)
	case "$KEY" in
		--no_lamp_check)
		no_lamp_check=1
		;;
		
		*)
		;;
	esac
done

# Setenforce to 0
setenforce 0 >> /dev/null 2>&1

# Flush the IP Tables
iptables -F >> /dev/null 2>&1
iptables -P INPUT ACCEPT >> /dev/null 2>&1

which firewalld > /dev/null 2>&1

if [ $? == 0 ] ; then
	if [ "`firewall-cmd --state 2>&1`" == running ] ; then
		firewall-cmd --zone=public --permanent --add-port={2002-2005/tcp,21/tcp,22/tcp,25/tcp,53/tcp,80/tcp,143/tcp,443/tcp,465/tcp,993/tcp,3306/tcp} >> /dev/null 2>&1
		/bin/systemctl restart firewalld >> /dev/null 2>&1
	fi
fi

# Clean the serverly file if present
if [[ $2 == "--SERVERLY=1" ]]; then
	rm -rf /root/webuzo.proc
	SERVERLY=true
	SERVERLY_LOG=/root/webuzo.proc
fi

function SERECHO {
	if [[ "$SERVERLY" = true ]]; then
		echo $1 >> $SERVERLY_LOG  2>&1
	fi
}

function LAMP_CHECK {
	
	if [ "$1" = redhat ] ; then
		APACHE=httpd
	elif [ "$1" = Ubuntu ]; then
		APACHE=apache2
	fi
	
	FLAG=FALSE
	
	if command -v "$APACHE" > /dev/null; then
		STR="Apache Detected, Please remove Apache from the Server to continue Installation"
		FLAG=TRUE
	elif command -v nginx > /dev/null; then
		STR="Nginx Detected, Please remove Nginx from the Server to continue Installation"
		FLAG=TRUE
	elif command -v mysql > /dev/null; then
		STR="MySQL Detected, Please remove MySQL from the Server to continue Installation"
		FLAG=TRUE
	elif command -v php > /dev/null; then
		STR="PHP Detected, Please remove PHP from the Server to continue Installation"
		FLAG=TRUE
	fi
	
	if [ "$FLAG" == TRUE ]; then
		echo "--------------------------------------------------------"
		echo -e "\033[31m$STR"
		echo -e "\033[37m--------------------------------------------------------"
		SERECHO $STR
		echo "Exiting installer"
		echo "--------------------------------------------------------"
		exit 1;
	fi
}

SOFTACULOUS_FILREPO=http://www.softaculous.com
VIRTUALIZOR_FILEREPO=http://files.virtualizor.com
FILEREPO=https://files.webuzo.com
LOG=/root/webuzo-install.log
SUCCESS_LOG=/root/webuzo-installed
EMPS=/usr/local/emps
CONF=/usr/local/webuzo/conf/webuzo

echo " Welcome to Webuzo Installer"
echo "--------------------------------------------------------"
echo " Installation Logs : tail -f /root/webuzo-install.log"
echo "--------------------------------------------------------"
echo " "
echo "=Welcome to Webuzo Installer=" >> $LOG 2>&1

#----------------------------------
# Some checks before we proceed
#----------------------------------

# Gets Distro type.

if [ -f /etc/debian_version ]; then
	OS=Ubuntu
	REL=$(cat /etc/issue)
elif [ -f /etc/redhat-release ]; then
	OS=redhat 
	REL=$(cat /etc/redhat-release)
else
	OS=$(uname -s)
	REL=$(uname -r)
fi

theos="$(echo $REL | egrep -i '(cent|Scie|Red|Ubuntu|AlmaLinux|cloudlinux|Rocky)' )"

if [ "$?" -ne "0" ]; then
	echo "Webuzo can be installed only on CentOS, Redhat, Ubuntu, AlmaLinux, Cloudlinux, Scientific Linux OR Rocky Linux"
	SERECHO "-1Webuzo can be installed only on CentOS, Redhat, Ubuntu, AlmaLinux, Cloudlinux, Scientific Linux OR Rocky Linux"
	echo "Exiting installer"
	exit 1;
fi

# Is Virtualizor installed ?
if [ -d /usr/local/virtualizor ]; then
	echo "Webuzo conflicts with Virtualizor."
	SERECHO "-1Webuzo conflicts with Virtualizor"
	echo "Exiting installer"
	exit 1;
fi

# Is Webuzo installed ?
if [ -d /usr/local/webuzo ]; then
	echo "Webuzo is already installed. Please rebuild the Server to install again."
	SERECHO "-1Webuzo is already installed. Please rebuild the Server to install again."
	echo "Exiting installer"
	echo " "
	echo "--------------------------------------------------------"
	exit 1;
fi

# Check IF LAMP stack is installed or not
if [ "$no_lamp_check" != "1" ]; then
	LAMP_CHECK $OS
fi

#----------------------------------
# Enabling Webuzo repo
#----------------------------------
if [ "$OS" = redhat ] ; then

	# Is yum there ?
	if ! [ -f /usr/bin/yum ] ; then
		echo "YUM wasnt found on the system. Please install YUM !"
		SERECHO "-1YUM wasnt found on the system. Please install YUM !"
		echo "Exiting installer"
		exit 1;
	fi
	
	#Enable powertool repo for centos 8 since the libnsl is moved in powertool repo
	OS_VERSION=$(rpm -q --queryformat '%{VERSION}' centos-release | cut -d. -f1)
	if [ "$OS_VERSION" = 8 ] ; then
		yum config-manager --set-enabled PowerTools
	fi
	
	# Download Webuzo repo
	#wget http://mirror.softaculous.com/webuzo/webuzo.repo -O /etc/yum.repos.d/webuzo.repo >> $LOG 2>&1
	
elif [ "$OS" = Ubuntu ]; then

	version=$(lsb_release -r | awk '{ print $2 }')
	current_version=$( echo "$version" | cut -d. -f1 )

	if [ "$current_version" -eq "15" ]; then
		echo "Webuzo is not supported on Ubuntu 15 !"
		SERECHO "-1Webuzo is not supported on Ubuntu 15 !"
		echo "Exiting installer"
		exit 1;
	fi
	
	# Is apt-get there ?
	if ! [ -f /usr/bin/apt-get ] ; then
		echo "APT-GET was not found on the system. Please install APT-GET !"
		SERECHO "-1APT-GET was not found on the system. Please install APT-GET !"
		echo "Exiting installer"
		exit 1;
	fi
	
	if [ "$current_version" -ge 22 ]; then
		# Prompt for the new password for 20 sec
		read -s -t 20 -p "Enter your root password: " new_password
		echo
		
		if [ -n "$new_password" ]; then
			read -s -p "Confirm your root password: " confirm_password
			echo
		fi
		
		# Check if the passwords match
		if [ -n "$new_password" ] && [ -n "$confirm_password" ]; then
			if [ "$new_password" != "$confirm_password" ]; then
				echo "Passwords do not match. we can not proceed the installation. Please run the installer again"
				exit 1
			fi
		fi
	fi
	
fi

# Create system user webuzo
useradd -r webuzo >> $LOG 2>&1

#----------------------------------
# Install  Libraries and Dependencies
#----------------------------------
echo "1) Installing Libraries and Dependencies"
echo "=1) Installing Libraries and Dependencies=" >> $LOG 2>&1

SERECHO "Installing Libraries and Dependencies"

if [ "$OS" = redhat  ] ; then
	
	theos="$(echo $REL | egrep -i '(AlmaLinux)')"
	if [ "$?" -eq "0" ]; then
		os_ver=$(echo "$REL" | awk '{print $3}')
		os_ver_numeric=$(echo "$os_ver" | tr -cd '[:digit:]')
		
		if [ "$os_ver_numeric" -le 88 ]; then
			rpm --import https://repo.almalinux.org/almalinux/RPM-GPG-KEY-AlmaLinux
		fi
	fi
	
	yum -y --skip-broken install ca-certificates gcc gcc-c++ curl unzip apr make cronie sendmail libnsl gawk sysstat tar atop psmisc yum-utils chrony util-linux >> $LOG 2>&1
	# Distro check for CentOS 7
	if [ -f /usr/bin/systemctl ] ; then
		yum -y install iptables-services >> $LOG 2>&1
	fi
	
	# Distro check for RHEL 9
	if [ -f /usr/bin/systemctl ] ; then
		yum -y --skip-broken install libxcrypt-compat initscripts >> $LOG 2>&1
	fi
	
else
	export DEBIAN_FRONTEND=noninteractive && apt-get update -y >> $LOG 2>&1
	apt-get install -y gcc g++ curl unzip make cron sendmail gawk sysstat tar atop psmisc chrony util-linux net-tools >> $LOG 2>&1
	export DEBIAN_FRONTEND=noninteractive && apt-get -q -y install iptables-persistent >> $LOG 2>&1
fi

# Replace password hash for ubuntu 22
if [ "$OS" = Ubuntu ]; then

	version=$(lsb_release -r | awk '{ print $2 }')
	current_version=$( echo "$version" | cut -d. -f1 )
	 
	if [ "$current_version" -ge 22 ]; then
		if [ -f /etc/pam.d/common-password ] ; then
			awk '{gsub(/obscure yescrypt/,"obscure sha512"); print}' /etc/pam.d/common-password > /etc/pam.d/common-password2 && mv /etc/pam.d/common-password2 /etc/pam.d/common-password
			awk '{gsub(/try_first_pass yescrypt/,"try_first_pass sha512"); print}' /etc/pam.d/common-password > /etc/pam.d/common-password2 && mv /etc/pam.d/common-password2 /etc/pam.d/common-password
		fi
		# Change the root password as the hashing method changed
		if [ -n "$new_password" ] && [ -n "$confirm_password" ]; then
			echo "root:$new_password" | chpasswd
		fi
	fi
fi

#----------------------------------
# Setting UP WEBUZO
#----------------------------------
echo "2) Setting UP WEBUZO"
echo "=2) Setting UP WEBUZO=" >> $LOG 2>&1
SERECHO "Setting UP WEBUZO"

# Stop all the services of EMPS if they were there.
/usr/local/emps/bin/mysqlctl stop >> $LOG 2>&1
/usr/local/emps/bin/nginxctl stop >> $LOG 2>&1
/usr/local/emps/bin/fpmctl stop >> $LOG 2>&1


#-------------------------------------
# Remove the EMPS package
rm -rf $EMPS >> $LOG 2>&1

# The necessary folders
mkdir $EMPS >> $LOG 2>&1

SERECHO "Downloading EMPS STACK"
wget -N -O $EMPS/EMPS.tar.gz "http://files.softaculous.com/emps.php?latest=1&arch=$ARCH" >> $LOG 2>&1

# Extract EMPS
tar -xvzf $EMPS/EMPS.tar.gz -C /usr/local/emps >> $LOG 2>&1

# Removing unwanted files
rm -rf $EMPS/EMPS.tar.gz >> $LOG 2>&1
rm -rf /usr/local/emps/bin/{my*,replace,innochecksum,resolveip,perror,resolve_stack_dump} >> $LOG 2>&1
rm -rf /usr/local/emps/{lib/plugin,COPYING,include,man} >> $LOG 2>&1
rm -rf /usr/local/emps/share/{errmsg-utf8.txt,charsets,hungarian,french,czech,italian,russian,spanish,swedish,japanese,english,slovak,german,dutch} >> $LOG 2>&1
rm -rf /usr/local/emps/share/{fill_help_tables.sql,my*,korean,portuguese,norwegian-ny,estonian,romanian,greek,ukrainian,serbian,norwegian,danish} >> $LOG 2>&1

#----------------------------------
# Download and Install Webuzo
#----------------------------------
echo "3) Downloading and Installing Webuzo"
echo "=3) Downloading and Installing Webuzo=" >> $LOG 2>&1
SERECHO "Downloading and Installing Webuzo"

# Create the folder
rm -rf /usr/local/webuzo
mkdir /usr/local/webuzo >> $LOG 2>&1

# Get our installer
wget -O /usr/local/webuzo/install.php $FILEREPO/new_install.inc >> $LOG 2>&1

echo "4) Downloading System Apps"
echo "=4) Downloading System Apps=" >> $LOG 2>&1
SERECHO "Downloading System Apps"

# Run our installer
/usr/local/emps/bin/php -d zend_extension=/usr/local/emps/lib/php/ioncube_loader_lin_5.3.so /usr/local/webuzo/install.php $*
phpret=$?
rm -rf /usr/local/webuzo/install.php >> $LOG 2>&1
rm -rf /usr/local/webuzo/upgrade.php >> $LOG 2>&1

# Was there an error
if ! [ $phpret == "8" ]; then
	echo " "
	echo "ERROR :"
	echo "There was an error while installing Webuzo"
	echo "=There was an error while installing Webuzo=" >> $LOG 2>&1
	SERECHO "-1There was an error while installing Webuzo"
	echo "Please check $LOG for errors"
	echo "Exiting Installer"
	echo "=Exiting Installer=" >> $LOG 2>&1
 	exit 1;
fi

# Disable selinux
if [ -f /etc/selinux/config ] ; then 
	mv /etc/selinux/config /etc/selinux/config_  
	echo "SELINUX=disabled" >> /etc/selinux/config 
	echo "SELINUXTYPE=targeted" >> /etc/selinux/config 
	echo "SETLOCALDEFS=0" >> /etc/selinux/config 
fi

#----------------------------------
# Starting Webuzo Services
#----------------------------------
echo "=Starting Webuzo Services=" >> $LOG 2>&1
/etc/init.d/webuzo restart >> $LOG 2>&1

#wget -O /usr/local/webuzo/universal.php $FILEREPO/universal.inc >> $LOG 2>&1

#-------------------------------------------
# FLUSH and SAVE IPTABLES / Start the CRON
#-------------------------------------------
service crond restart >> $LOG 2>&1

/sbin/iptables -F >> $LOG 2>&1

if [ "$OS" = redhat  ] ; then
	# Distro check for CentOS 7
	if [ -f /usr/bin/systemctl ] ; then
		/usr/libexec/iptables/iptables.init save >> $LOG 2>&1
	else
		/etc/init.d/iptables save >> $LOG 2>&1
	fi
	
	
	/usr/sbin/chkconfig crond on >> $LOG 2>&1
	
	/usr/sbin/chkconfig chronyd on >> $LOG 2>&1
	
elif [ "$OS" = Ubuntu ]; then
	iptables-save > /etc/iptables.rules >> $LOG 2>&1
	update-rc.d cron defaults >> $LOG 2>&1
	update-rc.d chrony defaults >> $LOG 2>&1
	/bin/ln -s /usr/lib/python2.7/plat-x86_64-linux-gnu/_sysconfigdata_nd.py /usr/lib/python2.7/
fi

echo "5) Installing Softaculous"
echo "=5) Installing Softaculous=" >> $LOG 2>&1
SERECHO "Installing Softaculous"

wget -O softaculous.sh -N http://files.softaculous.com/install.sh >> $LOG 2>&1
chmod 755 softaculous.sh >> $LOG 2>&1
./softaculous.sh --quick >> $LOG 2>&1

# Install ImunifyAV by default
if [ -f /usr/local/webuzo/tmp/install-imunifyav ] ; then 
	rm -rf /usr/local/webuzo/tmp/install-imunifyav
	wget -N https://files.webuzo.com/plugins/imunifyav/imunifyav.sh >> $LOG 2>&1
	chmod +x imunifyav.sh >> $LOG 2>&1
	./imunifyav.sh >> $LOG 2>&1
fi

#----------------------------------
# GET the IP
#----------------------------------
wget $FILEREPO/ip.php >> $LOG 2>&1 
ip=$(cat ip.php) 

service webuzo restart >> $LOG 2>&1 
service chronyd restart >> $LOG 2>&1 

clear
success_msg='----------------------------------------------------------------
 /$$      /$$ /$$$$$$$$ /$$$$$$$  /$$   /$$ /$$$$$$$$  /$$$$$$ 
| $$  /$ | $$| $$_____/| $$__  $$| $$  | $$|_____ $$  /$$__  $$
| $$ /$$$| $$| $$      | $$  \ $$| $$  | $$     /$$/ | $$  \ $$
| $$/$$ $$ $$| $$$$$   | $$$$$$$ | $$  | $$    /$$/  | $$  | $$
| $$$$_  $$$$| $$__/   | $$__  $$| $$  | $$   /$$/   | $$  | $$
| $$$/ \  $$$| $$      | $$  \ $$| $$  | $$  /$$/    | $$  | $$
| $$/   \  $$| $$$$$$$$| $$$$$$$/|  $$$$$$/ /$$$$$$$$|  $$$$$$/
|__/     \__/|________/|_______/  \______/ |________/ \______/
----------------------------------------------------------------
Congratulations, Webuzo has been successfully installed

You can now configure Softaculous Webuzo at the following URL :
https://'"$ip"':2005/

----------------------------------------------------------------
Thank you for choosing Webuzo !
----------------------------------------------------------------'

if [ "$OS" = Ubuntu ] && [ "$current_version" -ge 22 ]; then
	if [ -z "$new_password" ] && [ -z "$confirm_password" ]; then
		echo "Note : You will need to reset the root password in order to login Webuzo panel."
	fi
fi

echo "$success_msg"
echo "$success_msg" >> $LOG 2>&1

echo "=Webuzo Installed Successfully=" >> $LOG 2>&1
SERECHO "Webuzo Installation Done"

echo "1" > $SUCCESS_LOG 2>&1
