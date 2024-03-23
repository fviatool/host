#!/bin/bash

# Download the zip file from the GitHub repository
wget https://raw.githubusercontent.com/fviatool/host/main/static.zip

# Unzip the downloaded file and overwrite the contents of /www/server/panel/BTPanel/
unzip -o static.zip -d /www/server/panel/BTPanel/

# Remove the downloaded zip file
rm static.zip

# Enter SSH on the server
# Execute the commands 'bt', '9', and clear the panel cache
ssh user@your_server_ip << 'EOF'
bt
9
echo -e "Clearing panel cache..."
rm -rf /www/server/panel/data/templates/* && echo -e "Panel cache cleared."
EOF

# Prompt the user to refresh their browser (Ctrl + F5)
echo "Please refresh your browser (Ctrl + F5) to see the changes."p
