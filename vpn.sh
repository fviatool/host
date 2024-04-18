#!/bin/bash

# Cài đặt VPN server
wget https://get.vpnsetup.net -O vpn.sh 
sudo sh vpn.sh

# Cấu hình VPN server
cat << EOF > /etc/ipsec.conf
config setup
conn %default
  ikelifetime=60m
  keylife=20m
  rekeymargin=3m
  keyingtries=1
  keyexchange=ikev1
  authby=secret
  ike=aes128-sha1-modp2048!
  esp=aes128-sha1-modp2048!

conn myvpn
  keyexchange=ikev1
  left=%defaultroute
  auto=add
  authby=secret
  type=transport
  leftprotoport=17/1701
  rightprotoport=17/1701
  right=217.20.240.2
EOF

cat << EOF > /etc/ipsec.secrets
: PSK "987654321"
EOF

chmod 600 /etc/ipsec.secrets 
mv /etc/strongswan/ipsec.conf /etc/strongswan/ipsec.conf.old 2>/dev/null
mv /etc/strongswan/ipsec.secrets /etc/strongswan/ipsec.secrets.old 2>/dev/null
ln -s /etc/ipsec.conf /etc/strongswan/ipsec.conf
ln -s /etc/ipsec.secrets /etc/strongswan/ipsec.secrets

cat << EOF > /etc/xl2tpd/xl2tpd.conf
[lac myvpn]
lns = 217.20.240.2
ppp debug = yes
pppoptfile = /etc/ppp/options.l2tpd.client
length bit = yes
EOF

cat << EOF > /etc/ppp/options.l2tpd.client
ipcp-accept-local
ipcp-accept-remote
refuse-eap
require-chap
noccp
noauth
mtu 1280
mru 1280
noipdefault
defaultroute
usepeerdns
connect-delay 5000
name test
password test
EOF

chmod 600 /etc/ppp/options.l2tpd.client

# Khởi động VPN server
systemctl restart strongswan
systemctl restart xl2tpd

# Kết nối với VPN
echo "c myvpn" > /var/run/xl2tpd/l2tp-control
