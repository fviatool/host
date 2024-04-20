#!/bin/bash

set -e

[[ ! -f /etc/os-release ]] && echo "Can't find /etc/os-release file" && exit 1
source /etc/os-release

if [[ -x "$(command -v yum)" || -x "$(command -v dnf)" ]]; then
	RPM_PKG=1
elif [[ -x "$(command -v apt-get)" ]]; then
  	JETAPPS_REPO_DEB="$(mktemp)"
  	export DEBIAN_FRONTEND=noninteractive
  	APT_PKG=1
else 
	echo -en "Failed fetching package manager." 
	exit 1
fi

if [[ -n ${RPM_PKG} ]]; then

	echo -en "Installing jetapps repo package..."

	LATEST=""
	if [[ -f /etc/os-release ]]; then
		source /etc/os-release
		VERSION=$( echo $VERSION_ID | grep -oE '^[0-9]+' )
		[[ $VERSION -ge 9 ]] && LATEST="-4096"
	fi

	yum -y -q install https://repo.jetlicense.com/centOS/jetapps-repo$LATEST-latest.rpm --disablerepo=* >/dev/null
	echo -en "DONE\n"

	echo -en "Cleaning installed repos...."
	yum clean all --enablerepo=jetapps* >/dev/null
	echo -en "DONE\n"

	echo -en "Installing jetapps cli package..."
	yum -y -q install jetapps --disablerepo=* --enablerepo=jetapps >/dev/null
	echo -en "DONE\n"

	exit 0

elif [[ -n ${APT_PKG} ]]; then

	echo -en "Installing gnupg if needed..."
	apt-get install -y gnupg >/dev/null
	echo -en "DONE\n"

	echo -en "Downloading jetapps repo package..."
	wget -qO "$JETAPPS_REPO_DEB" "https://repo.jetlicense.com/$ID/jetapps-repo-latest_amd64.deb" >/dev/null
	echo -en "DONE\n"

	echo -en "Installing jetapps repo package..."
	dpkg -i "$JETAPPS_REPO_DEB" >/dev/null
	echo -en "DONE\n"

	rm -f "$JETAPPS_REPO_DEB" >/dev/null
	echo -en "Reloading JetApps repositories..."
	apt-get update >/dev/null
	echo -en "DONE\n"

	echo -en "Installing jetapps cli package..."
	apt-get install -y jetapps >/dev/null
	echo -en "DONE\n"
	exit 0

fi
