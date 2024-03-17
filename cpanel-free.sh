#!/bin/bash

# Function to execute a command and check for errors
execute_command() {
    command="$1"
    echo "Executing: $command"
    if eval "$command"; then
        echo "Command executed successfully."
    else
        echo "Error executing command: $command"
        exit 1
    fi
}

# Function to display a message
display_message() {
    message="$1"
    echo "$message"
}

# Update system
display_message "Updating system..."
execute_command "sudo yum update && sudo yum upgrade -y"

# Install Apache HTTP Server
display_message "Installing Apache HTTP Server..."
execute_command "sudo yum install httpd"
execute_command "sudo systemctl restart httpd"

# Install and configure firewall
display_message "Installing and configuring firewall..."
execute_command "sudo yum install firewalld -y"
execute_command "sudo systemctl start firewalld"
execute_command "sudo systemctl enable firewalld"
execute_command "sudo systemctl status firewalld"
execute_command "sudo firewall-cmd --permanent --add-port=80/tcp"
execute_command "sudo firewall-cmd --permanent --add-port=443/tcp"
execute_command "sudo firewall-cmd --permanent --add-port=2087/tcp"
execute_command "sudo firewall-cmd --permanent --add-port=2083/tcp"
execute_command "sudo firewall-cmd --permanent --add-port=3306/tcp"
execute_command "sudo systemctl restart firewalld"

# Set permissions for Apache
display_message "Setting permissions for Apache..."
execute_command "sudo chcon -Rt httpd_sys_rw_content_t /var/www"

# Install PHP
display_message "Installing PHP..."
execute_command "sudo yum install php"
execute_command "sudo dnf install php php-opcache php-gd php-curl php-mysqlnd php-xml php-mbstring php-pecl-apcu"
execute_command "sudo systemctl enable --now php-fpm"

# Restart Apache
display_message "Restarting Apache..."
execute_command "sudo service httpd restart"

# Install Perl
display_message "Installing Perl..."
execute_command "sudo yum install perl"

# Install cPanel
display_message "Downloading and installing cPanel..."
execute_command "curl -o latest -L https://securedownloads.cpanel.net/latest"
execute_command "sudo sh latest"

echo "Setup completed successfully."
