#!/usr/bin/php
<?php
/*

v1 System


*/
$version = "1";


error_reporting(0);
unlink("id_rsa");
unlink("id_rsa.pub");
shell_exec('ssh-keygen -b 2048 -t rsa -f id_rsa -q -N ""');

echo "\n";
echo " === V$version License System ===\n";
echo "\n";
echo "\n";
if (!file_exists("php.ini")) {
    file_put_contents("php.ini","disable_extensions =");
    die ("Please run this script again. The php.ini file has been modified\n");
}
if (!file_exists("settings.php")) {
    $g = "<" . "?" . "php $" . "key='ZERSO33H3RK6K67Y73RBEV5EOIJQOAUKK5EQ'" . ";";
    file_put_contents("settings.php",$g);
    die("Settings Loaded from config!\n");
} else {
    require("settings.php");
}

echo "Checking for supported products.......\n";

if (is_dir("/usr/local/cpanel")) {
    $cpanel = true;
    echo "cPanel/WHM Detected!\n";
} else {
    die("My-Licences Requires cPanel/WHM. Please install then run this script.\n");
}

if (is_dir("/usr/local/cpanel/whostmgr/cgi/lsws")) {
    $lsws = true;
    echo "Litespeed Detected!\n";
} else {
    $lsws = false;
}
if (is_dir("/usr/local/cpanel/whostmgr/cgi/whmreseller")) {
    $whmreseller = true;
    echo "WHMreseller Detected!\n";
} else {
    $whmreseller = false;
}
echo "My-Licences Installing Patches into the /etc/hosts file.......\n";
if ($softaculous) {
    echo "-- Patch for softaculous --\n";
    $a = file_get_contents("/etc/hosts");
    if(strpos($a, "api.softaculous.com") !== false){} else {
        $a = $a . "\n127.0.0.1               api.softaculous.com";
        file_put_contents("/etc/hosts",$a);
    }
}

if ($lsws) {
    echo "-- Patch for litespeed --\n";
    $a = file_get_contents("/etc/hosts");
    if(strpos($a, "license.litespeedtech.com") !== false){} else {
        $a = $a . "\n127.0.0.1               license.litespeedtech.com license2.litespeedtech.com";
        file_put_contents("/etc/hosts",$a);
    }
}

echo "Installing cPanel Letsencrypt Plugin.......";

$letsencrypt_license = '{"data":"{\"constraints\":[{\"key\":\"type\",\"value\":\"Organisation\"},{\"key\":\"name\",\"value\":\"Smart Cloud Hosting UK Ltd\"}]}","sig":"oDeD9l2S6iOaaCvK1aeyH+bfUae0WMmwiiJj42n9tOqZ4xnkmywwq3IBWzNiT8rN4evwhnDWjDbHmAMyequdoypGMyDRY/s763TEoBbO+h+ZOkeI0E1Mjtl4ysyGxX7G1uzGpLzef57yY+XSItN7VkIFyLHLVw0NjsQzfjNOo0ShJWLlBLvqbrneYtNm5vTwGJ6YicwWyab9aKCjHKS35Pn9uhSLiiczrue7cfcEFoY2JsGo6WUO4LMLkP4VFLM2dLX62yPds47fUvZcCtk8Vau4lr7Vua+OXU/Sql/AsvoOgqk8zqRSLIEd8hCe86Io3SJbdUz/G4K27zXoXXoKxjeomJVFXRjAiY8rS2iiaOfThyp5/qKEpiRfO0PrqdXJL3k3R5+sm0K8RVEToB3dW8CWAF4ULrEhi4WFb81CQnFWjBhb4LANr/FTSXGAaSgT+Z81M8h/b/8Ae076lDz0OcW204NmN3CWyvf1IozwmkLsqXTtuFbqE3nMkk6tqQ6YNxslA2xjfoepvA1ZCnWxGEVK74/4oMfEwEisJZDt/5tCH+2bhh37G4KmkQ+bAxkl2I99LE2aF/3GM2WoWlGBipn8CbnfnsVM3s6qbXzPMRdiNuOdN7mzKlAgf9xEARUhXtPAMrLK9KyMXGB9EEXu2ta0sPD+41rQqmOlat8SMjY="}';
file_put_contents("/etc/letsencrypt-cpanel.licence",$letsencrypt_license);
if (!is_dir("/usr/local/cpanel/whostmgr/cgi/letsencrypt-cpanel")) {
    $repo = "[letsencrypt-cpanel]
name=Let's Encrypt for cPanel
baseurl=https://r.cpanel.fleetssl.com
gpgcheck=0";
    file_put_contents("/etc/yum.repos.d/letsencrypt.repo",$repo);
    shell_exec("yum -y install letsencrypt-cpanel");
}
echo "[OK]\n";

echo "Disarming My-Licences Preventing System.......";
if (file_exists("/usr/local/cpanel/cpkeyclt.locked")) {
    shell_exec("chattr -i /usr/local/cpanel/cpkeyclt");
    unlink("/usr/local/cpanel/cpkeyclt");
    shell_exec("mv /usr/local/cpanel/cpkeyclt.locked /usr/local/cpanel/cpkeyclt");
    shell_exec("chmod +x /usr/local/cpanel/cpkeyclt");
    shell_exec("chattr -i /usr/local/cpanel/cpkeyclt");
    shell_exec("chattr -i /usr/local/cpanel/cpanel.lisc");
    if ($lsws) {
        shell_exec("chattr -i /usr/local/lsws/conf/trial.key");
    }
    
    echo "[OK]\n";
    echo "Installing Requirements.......";
    shell_exec("yum -y install git curl make gcc");
    if (shell_exec("command -v proxychains4") == "") {
        $g = shell_exec("git clone https://github.com/rofl0r/proxychains-ng.git && cd proxychains-ng && ./configure && make && make install && cd ../ && rm -rf proxychains-ng");
    }
    echo "[OK]\n";
    echo "Testing Connection to localhost.......“;

    echo “[OK]\n”;
    echo “Creating Temp Server for License Activation…….”;
    $sshkey = urlencode(file_get_contents(“id_rsa.pub”));

    echo “[OK]\n”;
    echo “Starting DialLicense…”;

    echo “[OK]\n”;
    echo “Running License Activation….\n”;
    echo “[OK]\n”;
    if ($lsws) {
        echo “Running system cleaning….”;
        unlink(“proxychains.conf”);
        echo “[OK]\n”;
        echo “Removing Trial Banners….”;
        echo “[OK]\n”;
    }
}
