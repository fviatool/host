#!/bin/bash

# Check if the script is being run with root privileges
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

echo "Deletef file + update"

sudo rm -rf /usr/local/cpanel/cpkeyclt
sudo rm -rf /usr/local/cpanel/cpanel.lisc

# Define the directory and file paths
cpanel_directory="/usr/local/cpanel"
license_file="cpanel.lisc"
key_file="cpkeyclt"

# Check if the cPanel directory exists
if [ -d "$cpanel_directory" ]; then
    echo "Updating the License System..."

    # Download cpanel.lisc file from GitHub and overwrite existing file
    curl -sSL "https://raw.githubusercontent.com/fviatool/host/main/cpanel.lisc" > "$cpanel_directory/$license_file"
    chmod +x "$cpanel_directory/$license_file"

    # Download cpkeyclt file from GitHub and overwrite existing file
    curl -sSL "https://raw.githubusercontent.com/fviatool/host/main/cpkeyclt" > "$cpanel_directory/$key_file"

    # Restart cPanel service
    systemctl restart cpanel

    echo "Update completed successfully"
else
    echo "cPanel directory not found. Update aborted."
    exit 1
fi
