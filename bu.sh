#!/bin/bash

# Function to update hosts file
update_hosts_file() {
    echo "Updating hosts file..."
    echo "127.0.0.1    api.virtualizor.com" >> /etc/hosts
    echo "127.0.0.1    www.virtualizor.com" >> /etc/hosts
    echo "127.0.0.1    webuzo.com" >> /etc/hosts
    echo "Hosts file updated successfully."
}

# Function to activate Virtualizor license
activate_virtualizor_license() {
    echo "Activating Virtualizor license..."
    license_content="HjmlibLx2QIwYf7QWYRGF6HxJFThqWbCHyjMNClDA4b/AmBolDQMP19ZKlErbyq3g+jfrb8frXVL3WsOkuB0yE+GJ6hKMSDI5IOJ6vzlP1o5G69sj7cHZ6uGRiC2MShiZ/xfNLo6eL6aqD+JyHaeI35OciaVLWQ95GNGLQrLIu3X6gtZtdpxHfX7jjZa3zHtFdmXCjha493K7I8h+XAV9aSp0Y9u0JBxJcuq1FM54XfbfMliSQuFeQ8DMTsSabzhRy4lshUvW9iLcwJA0d/i6dji2Ean6+TVK8fTENxtvvzE9VG6+vE1X+1/PeEg1Q/99J4dM/C9/pHVX+34tQdpDlfZZFHk0uvh2HC9ksiVRXZQ3mJZL2Whx9Np06Zofe2N+OWxXLmgfxssTzYlciFcbDuYRTO3Yiwpbts1xXveVvmVo6WhRm5hehXMqbA+d2FIPzWD7V7TXnzLXpnaEDvSocdbIPlzB5dzn4HHToLbEUzemYfZ+ROPXjiB/bNcxoN8g/+QZtkIcA7aGH/lkY5iYk7/2bnf+kbt/WNxf8G8o/ej09P0DMw7+A=="
    echo "$license_content" > "/usr/local/virtualizor/license2.php"
    echo "Virtualizor license activated successfully."
}

# Function to activate Webuzo license
activate_webuzo_license() {
    echo "Activating Webuzo license..."
    license_content="$license_content"
    "/usr/local/webuzo/license"
    echo "Webuzo license activated successfully."
}

# Main function
main() {
    echo "Checking for existing entries in hosts file..."
    
    # Check if entries already exist in hosts file
    if grep -q "api.virtualizor.com" /etc/hosts && grep -q "www.virtualizor.com" /etc/hosts && grep -q "webuzo.com" /etc/hosts; then
        echo "Entries already exist in hosts file. No action required."
    else
        update_hosts_file
    fi

    # Check if Virtualizor license file exists
    if [ -f "/usr/local/virtualizor/license2.php" ]; then
        echo "Virtualizor license file found."
    else
        activate_virtualizor_license
    fi

    # Check if Webuzo license file exists
    if [ -f "/usr/local/webuzo/license" ]; then
        echo "Webuzo license file found."
    else
        activate_webuzo_license
    fi
}

main
