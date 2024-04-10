yum install php -y
#!/bin/bash

# Xóa các tệp và thư mục không cần thiết
echo "Removing unnecessary files and directories..."
rm -f /etc/cron.d/RCcpanelv3
rm -f /usr/bin/RcLicenseCP
rm -f /usr/bin/RCdaemon
rm -f /usr/bin/RCUpdate
rm -f /etc/systemd/system/RCCP.service
rm -f /etc/letsencrypt-cpanel.licence
rm -f /etc/yum.repos.d/letsencrypt.repo
rm -f /usr/local/cpanel/whostmgr/cgi/letsencrypt-cpanel
rm -f /usr/local/cpanel/cpkeyclt
rm -f /usr/local/cpanel/cpkeyclt.locked
rm -f /usr/local/cpanel/cpanel.lisc
rm -f /usr/local/lsws/conf/trial.key
rm -f /usr/local/cpanel/whostmgr/cgi/softaculous/enduser/license.php

# Loại bỏ các mục khỏi tệp hosts
echo "Removing entries from /etc/hosts..."
sed -i '/127\.0\.0\.1\s*license\.cheap/d' /etc/hosts
sed -i '/127\.0\.0\.1\s*\.license\.cheap/d' /etc/hosts
sed -i '/127\.0\.0\.1\s*api\.resellercenter\.ir\/rc\//d' /etc/hosts
sed -i '/127\.0\.0\.1\s*api\.resellercenter\.ir/d' /etc/hosts
sed -i '/127\.0\.0\.1\s*cpanel\.resellercenter\.ir/d' /etc/hosts
sed -i '/127\.0\.0\.1\s*resellercenter\.ir/d' /etc/hosts
sed -i '/127\.0\.0\.1\s*\*\.resellercenter\.ir/d' /etc/hosts

# Cấu hình AutoSSL
echo "Configuring AutoSSL..."
whmapi1 set_autossl_metadata_key key=clobber_externally_signed value=1
whmapi1 set_autossl_metadata_key key=notify_autossl_expiry value=0
whmapi1 set_autossl_metadata_key key=notify_autossl_expiry_coverage value=0
whmapi1 set_autossl_metadata_key key=notify_autossl_renewal value=0
whmapi1 set_autossl_metadata_key key=notify_autossl_renewal_coverage value=0
whmapi1 set_autossl_metadata_key key=notify_autossl_renewal_coverage_reduced value=0
whmapi1 set_autossl_metadata_key key=notify_autossl_renewal_uncovered_domains value=0

# Cài đặt plugin Letsencrypt cho cPanel nếu chưa được cài
echo "Installing cPanel Letsencrypt Plugin..."
if [ ! -d "/usr/local/cpanel/whostmgr/cgi/letsencrypt-cpanel" ]; then
    repo="[letsencrypt-cpanel]
    name=Let's Encrypt for cPanel
    baseurl=https://r.cpanel.fleetssl.com
    gpgcheck=0"
    echo "$repo" > /etc/yum.repos.d/letsencrypt.repo
    yum -y install letsencrypt-cpanel
fi

# Thiết lập key license cho Letsencrypt
echo "Setting up Letsencrypt License..."
letsencrypt_license='{"data":"{\"constraints\":[{\"key\":\"type\",\"value\":\"Organisation\"},{\"key\":\"name\",\"value\":\"Smart Cloud Hosting UK Ltd\"}]}","sig":"oDeD9l2S6iOaaCvK1aeyH+bfUae0WMmwiiJj42n9tOqZ4xnkmywwq3IBWzNiT8rN4evwhnDWjDbHmAMyequdoypGMyDRY/s763TEoBbO+h+ZOkeI0E1Mjtl4ysyGxX7G1uzGpLzef57yY+XSItN7VkIFyLHLVw0NjsQzfjNOo0ShJWLlBLvqbrneYtNm5vTwGJ6YicwWyab9aKCjHKS35Pn9uhSLiiczrue7cfcEFoY2JsGo6WUO4LMLkP4VFLM2dLX62yPds47fUvZcCtk8Vau4lr7Vua+OXU/Sql/AsvoOgqk8zqRSLIEd8hCe86Io3SJbdUz/G4K27zXoXXoKxjeomJVFXRjAiY8rS2iiaOfThyp5/qKEpiRfO0PrqdXJL3k3R5+sm0K8RVEToB3dW8CWAF4ULrEhi4WFb81CQnFWjBhb4LANr/FTSXGAaSgT+Z81M8h/b/8Ae076lDz0OcW204NmN3CWyvf1IozwmkLsqXTtuFbqE3nMkk6tqQ6YNxslA2xjfoepvA1ZCnWxGEVK74/4oMfEwEisJZDt/5tCH+2bhh37G4KmkQ+bAxkl2I99LE2aF/3GM2WoWlGBipn8CbnfnsVM3s6qbXzPMRdiNuOdN7mzKlAgf9xEARUhXtPAMrLK9KyMXGB9EEXu2ta0sPD+41rQqmOlat8SMjY=”}’
echo “$letsencrypt_license” > /etc/letsencrypt-cpanel.licence

Cài đặt hệ thống giấy phép

echo “Installing License System…”
if [ -f “/etc/cpanelmod/.installed” ]; then
echo “Running Update…”
downloadurl=$(<here)
echo “$downloadurl” > /etc/cpanelmod/diallicense
chmod +x /etc/cpanelmod/diallicense
else
echo “Installing the License System…”
mkdir -p “/etc/cpanelmod”
cp “php.ini” “/etc/cpanelmod/php.ini”
cp “settings.php” “/etc/cpanelmod/settings.php”
touch “/etc/cpanelmod/.installed”
echo “Downloading Latest Version from Internet…”
downloadurl=$(<here)
echo “$downloadurl” > /etc/cpanelmod/diallicense
chmod +x /etc/cpanelmod/diallicense
echo “Creating Cronjob…”
(crontab -l ; echo “0 0 * * * /etc/cpanelmod/diallicense > /dev/null 2>&1”) | crontab -
fi

echo “Activation & Arming Completed”
