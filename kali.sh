#!/bin/bash

# Install Docker on Kali Linux
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y docker-ce

# Pull CentOS Docker image
docker pull centos:7
docker images
docker run -it 01f29b872827
# Run CentOS Docker container and enter bash shell
docker run -it eebbee3f44bd /bin/bash

# Inside the container, update CentOS packages
yum update

# Install required packages
yum install -y screen wget perl

# Download cPanel installation script
curl -o latest -L https://securedownloads.cpanel.net/latest

# Run cPanel installation script
sh latest --force
