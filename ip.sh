#!/bin/bash

# Function to get public IPv4 address
get_ipv4() {
    curl -4 -s icanhazip.com
}

# Function to update IPv6 configuration
update_ipv6() {
    local ipv4="$1"
    local ipc="$(echo $ipv4 | cut -d'.' -f3)"
    local ipd="$(echo $ipv4 | cut -d'.' -f4)"
    
    local ipv6_address=""
    local gateway6_address=""
    local interface_name=""

    if [ "$ipc" = "4" ]; then
        ipv6_address="2403:6a40:0:40::$ipd:0000/64"
        gateway6_address="2403:6a40:0:40::1"
    elif [ "$ipc" = "5" ]; then
        ipv6_address="2403:6a40:0:41::$ipd:0000/64"
        gateway6_address="2403:6a40:0:41::1"
    elif [ "$ipc" = "244" ]; then
        ipv6_address="2403:6a40:2000:244::$ipd:0000/64"
        gateway6_address="2403:6a40:2000:244::1"
    else
        ipv6_address="2403:6a40:0:$ipc::$ipd:0000/64"
        gateway6_address="2403:6a40:0:$ipc::1"
    fi

    # Check network interface
    local interface=""
    local netplan_path=""
    if [ -e "/etc/sysconfig/network-scripts/ifcfg-eth0" ]; then
        interface_name="eth0"
        netplan_path="/etc/sysconfig/network-scripts/ifcfg-eth0"
    elif [ -e "/etc/netplan/99-netcfg-vmware.yaml" ]; then
        interface_name="$(ls /sys/class/net | grep e)"
        netplan_path="/etc/netplan/99-netcfg-vmware.yaml"
    elif [ -e "/etc/netplan/50-cloud-init.yaml" ]; then
        interface_name="$(ls /sys/class/net | grep e)"
        netplan_path="/etc/netplan/50-cloud-init.yaml"
    else
        echo "Cannot find network interface configuration."
        exit 1
    fi

    # Update IPv6 configuration
    sed -i "/^IPV6ADDR/c IPV6ADDR=$ipv6_address" $netplan_path
    sed -i "/^IPV6_DEFAULTGW/c IPV6_DEFAULTGW=$gateway6_address" $netplan_path

    # Apply changes
    if [ -x "$(command -v netplan)" ]; then
        sudo netplan apply
    elif [ -x "$(command -v systemctl)" ]; then
        sudo systemctl restart network
    elif [ -x "$(command -v service)" ]; then
        sudo service network restart
    else
        echo "Cannot restart network service."
        exit 1
    fi
}

# Function to ping6 Google
ping_google6() {
    ping6 -c 3 google.com
}

# Get IPv4 address
ipv4_address=$(get_ipv4)

# Check if IPv4 address is valid
if [[ -n "$ipv4_address" ]]; then
    echo "IPv4 Address: $ipv4_address"
    update_ipv6 "$ipv4_address"
    echo "IPv6 configuration updated successfully."
    echo "Pinging Google over IPv6..."
    ping_google6
else
    echo "Failed to retrieve valid IPv4 address."
    exit 1
fi
