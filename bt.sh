#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

if [ $(whoami) != "root" ]; then
	echo "请使用root权限执行宝塔安装命令！"
	exit 1
fi

is64bit=$(getconf LONG_BIT)
if [ "${is64bit}" != '64' ]; then
	Red_Error "抱歉, 当前面板版本不支持32位系统, 请使用64位系统或安装宝塔5.9!"
fi

Centos6Check=$(cat /etc/redhat-release | grep ' 6.' | grep -iE 'centos|Red Hat')
if [ "${Centos6Check}" ]; then
	echo "Centos6不支持安装宝塔面板，请更换Centos7/8安装宝塔面板"
	exit 1
fi 

UbuntuCheck=$(cat /etc/issue | grep Ubuntu | awk '{print $2}' | cut -f 1 -d '.')
if [ "${UbuntuCheck}" ] && [ "${UbuntuCheck}" -lt "16" ]; then
	echo "Ubuntu ${UbuntuCheck}不支持安装宝塔面板，建议更换Ubuntu18/20安装宝塔面板"
	exit 1
fi

cd ~
setup_path="/www"
python_bin=$setup_path/server/panel/pyenv/bin/python
cpu_cpunt=$(cat /proc/cpuinfo | grep processor | wc -l)

if [ "$1" ]; then
	IDC_CODE=$1
fi

GetSysInfo() {
	if [ -s "/etc/redhat-release" ]; then
		SYS_VERSION=$(cat /etc/redhat-release)
	elif [ -s "/etc/issue" ]; then
		SYS_VERSION=$(cat /etc/issue)
	fi
	SYS_INFO=$(uname -a)
	SYS_BIT=$(getconf LONG_BIT)
	MEM_TOTAL=$(free -m | grep Mem | awk '{print $2}')
	CPU_INFO=$(getconf _NPROCESSORS_ONLN)

	echo -e ${SYS_VERSION}
	echo -e Bit:${SYS_BIT} Mem:${MEM_TOTAL}M Core:${CPU_INFO}
	echo -e ${SYS_INFO}
	echo -e "请截图以上报错信息发帖至论坛www.bt.cn/bbs求助"
}

Red_Error() {
	echo '================================================='
	printf '\033[1;31;40m%b\033[0m\n' "$@"
	GetSysInfo
	exit 1
}

Lock_Clear() {
	if [ -f "/etc/bt_crack.pl" ]; then
		chattr -R -ia /www
		chattr -ia /etc/init.d/bt
		\cp -rpa /www/backup/panel/vhost/* /www/server/panel/vhost/
		mv /www/server/panel/BTPanel/__init__.bak /www/server/panel/BTPanel/__init__.py
		rm -f /etc/bt_crack.pl
	fi
}

Install_Check() {
	if [ "${INSTALL_FORCE}" ]; then
		return
	fi
	echo -e "----------------------------------------------------"
	echo -e "检查已有其他Web/mysql环境，安装宝塔可能影响现有站点及数据"
	echo -e "Web/mysql service is alreday installed,Can't install panel"
	echo -e "----------------------------------------------------"
	echo -e "已知风险/Enter yes to force installation"
	yes="yes"
	if [ "$yes" != "yes" ]; then
		echo -e "------------"
		echo "取消安装"
		exit
	fi
	INSTALL_FORCE="true"
}

System_Check() {
	MYSQLD_CHECK=$(ps -ef | grep mysqld | grep -v grep | grep -v /www/server/mysql)
	PHP_CHECK=$(ps -ef | grep php-fpm | grep master | grep -v /www/server/php)
	NGINX_CHECK=$(ps -ef | grep nginx | grep master | grep -v /www/server/nginx)
	HTTPD_CHECK=$(ps -ef | grep -E 'httpd|apache' | grep -v /www/server/apache | grep -v grep)
	if [ "${PHP_CHECK}" ] || [ "${MYSQLD_CHECK}" ] || [ "${NGINX_CHECK}" ] || [ "${HTTPD_CHECK}" ]; then
		Install_Check
	fi
}

Get_Pack_Manager() {
	if [ -f "/usr/bin/yum" ] && [ -d "/etc/yum.repos.d" ]; then
		PM="yum"
	elif [ -f "/usr/bin/apt-get" ] && [ -f "/usr/bin/dpkg" ]; then
		PM="apt-get"		
	fi
}

Auto_Swap() {
	swap=$(free | grep Swap | awk '{print $2}')
	if [ "${swap}" -eq "0" ]; then
		dd if=/dev/zero of=/www/swap bs=1M count=1024
		mkswap /www/swap
		swapon /www/swap
		echo '/www/swap swap swap defaults 0 0' >>/etc/fstab
	fi
}

Install_Pack() {
	if [ "${PM}" = "yum" ]; then
		yum=$(which yum)
		${yum} -y install wget curl python-devel python3-devel unzip gcc
	elif [ "${PM}" = "apt-get" ]; then
		apt-get update -y
		apt-get -y install wget curl python-dev python3-dev unzip build-essential
	fi
}

Deps_Opt() {
	OldVersion=$(cat /www/server/panel/class/common.py | grep "oldVersion = '.*'" | grep -oE "[0-9.]+" | head -1)
	if [ "${OldVersion}" != "" ]; then
		curl -o /www/server/panel/data/nonlocal.zip http://download.bt.cn/install/nonlocal.zip -s
		unzip -o /www/server/panel/data/nonlocal.zip -d /www/server/panel/
		rm -f /www/server/panel/data/nonlocal.zip
	fi
}

Download_Python() {
	mkdir -p /www/server/panel/pyenv
	VerDate=$(curl -sS --connect-timeout 5 -m 60 https://www.python.org/ftp/python/${PYTHON_VERSION}/ | grep 'href=".*.tar.xz"' | grep -oE "[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}" | sort -r | head -1)
	PythonFile=$(curl -sS --connect-timeout 5 -m 60 https://www.python.org/ftp/python/${PYTHON_VERSION}/ | grep "href=\"Python-${VerDate}" | grep -oE "Python-${VerDate}\..*tar.xz" | head -1)
	wget -O /www/server/panel/pyenv/${PythonFile} https://www.python.org/ftp/python/${PYTHON_VERSION}/${PythonFile} -T 5
	if [ ! -f "/www/server/panel/pyenv/${PythonFile}" ]; then
		Red_Error "Python下载失败，请手动在网站https://www.python.org/ftp/python/${PYTHON_VERSION}/下载Python压缩包上传到/www/server/panel/pyenv目录"
	fi
}

Install_Python() {
	cd /www/server/panel/pyenv
	tar xvf ${PythonFile} -C /www/server/panel/pyenv/ > /dev/null 2>&1
	PY_NAME=$(ls -l /www/server/panel/pyenv | grep "^d" | awk '{print $NF}' | grep Python)
	if [ ! -d "/www/server/panel/pyenv/${PY_NAME}" ]; then
		Red_Error "Python解压失败，请检查磁盘空间是否充足，手动解压Python压缩包"
	fi
	cd ${PY_NAME}
	./configure --prefix=/www/server/panel/pyenv --enable-optimizations
	make -j${cpu_cpunt} && make install
	rm -f /www/server/panel/pyenv/${PythonFile}
}

Install_Setup() {
	mkdir -p ${setup_path}
	cd ${setup_path}
	wget -O ${setup_path}/panel.zip ${download_Url}/install/src/panel6.zip -T 5
	unzip -o ${setup_path}/panel.zip -d ${setup_path}/ > /dev/null 2>&1
	mv ${setup_path}/panel6/* ${setup_path}/
	rm -rf ${setup_path}/panel6
	rm -f ${setup_path}/panel.zip
	if [ ! -f "${setup_path}/server/panel/pyenv/bin/python" ]; then
		Red_Error "Python编译失败，请尝试手动安装或者联系BT宝塔技术支持"
	fi
}

Install_Main() {
echo > /www/server/panel/data/bind.pl
echo -e "=================================================================="
echo -e "\033[32mCongratulations! Installed successfully!\033[0m"
echo -e "=================================================================="
echo  "外网面板地址: http://${getIpAddress}:${panelPort}${auth_path}"
echo  "内网面板地址: http://${LOCAL_IP}:${panelPort}${auth_path}"
echo -e "username: $username"
echo -e "password: $password"
echo -e "\033[33mIf you cannot access the panel,\033[0m"
echo -e "\033[33mrelease the following panel port [${panelPort}] in the security group\033[0m"
echo -e "\033[33m若无法访问面板，请检查防火墙/安全组是否有放行面板[${panelPort}]端口\033[0m"
echo -e "=================================================================="

endTime=`date +%s`
((outTime=($endTime-$startTime)/60))
echo -e "Time consumed:\033[32m $outTime \033[0mMinute!"

