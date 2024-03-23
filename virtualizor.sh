#!/bin/bash

# Virtualizor v1 System
version="1"

echo "Checking for supported products......."
echo "My-Licences Installing Patches into the /etc/hosts file......."

# Update hosts file
echo -e "\n127.0.0.1               api.virtualizor.com" >> /etc/hosts
echo -e "127.0.0.1               www.virtualizor.com" >> /etc/hosts

echo "[OK]"

# Remove old license file
rm -f /usr/local/virtualizor/license2.php

# Activate license
license_content="HjmlibLx2QIwYf7QWYRGF6HxJFThqWbCHyjMNClDA4b/AmBolDQMP19ZKlErbyq3g+jfrb8frXVL3WsOkuB0yE+GJ6hKMSDI5IOJ6vzlP1o5G69sj7cHZ6uGRiC2MShiZ/xfNLo6eL6aqD+JyHaeI35OciaVLWQ95GNGLQrLIu3X6gtZtdpxHfX7jjZa3zHtFdmXCjha493K7I8h+XAV9aSp0Y9u0JBxJcuq1FM54XfbfMliSQuFeQ8DMTsSabzhRy4lshUvW9iLcwJA0d/i6dji2Ean6+TVK8fTENxtvvzE9VG6+vE1X+1/PeEg1Q/99J4dM/C9/pHVX+34tQdpDlfZZFHk0uvh2HC9ksiVRXZQ3mJZL2Whx9Np06Zofe2N+OWxXLmgfxssTzYlciFcbDuYRTO3Yiwpbts1xXveVvmVo6WhRm5hehXMqbA+d2FIPzWD7V7TXnzLXpnaEDvSocdbIPlzB5dzn4HHToLbEUzemYfZ+ROPXjiB/bNcxoN8g/+QZtkIcA7aGH/lkY5iYk7/2bnf+kbt/WNxf8G8o/ej09P0DMw7+A=="
echo "$license_content" > /usr/local/virtualizor/license2.php

# Make the script executable
chmod +x "$0"
