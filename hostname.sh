#!/bin/bash

# Set new hostname
new_hostname="congcufacebook.com"

# Set hostname temporarily
sudo hostnamectl set-hostname $new_hostname

# Set hostname permanently
sudo sed -i "s/127.0.1.1.*/127.0.1.1\t$new_hostname/" /etc/hosts
sudo sed -i "s/$HOSTNAME/$new_hostname/" /etc/hostname

# Restart networking service
sudo systemctl restart systemd-networkd

echo "Hostname set to $new_hostname"
