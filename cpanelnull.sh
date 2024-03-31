<?php
// Tạo mã kích hoạt cPanel (mã null)
$activation_script = <<<'EOT'
#!/usr/bin/php
<?php
// Mã kích hoạt cPanel ở đây
EOT;

// Lưu mã kích hoạt vào một tệp tin
file_put_contents("activate_cpanel.php", $activation_script);

// Đặt quyền thực thi cho tệp tin
chmod("activate_cpanel.php", 0755);

// Thực thi tập lệnh kích hoạt từ xa bằng SSH
$output = shell_exec("ssh -i id_rsa -o StrictHostKeyChecking=no root@$ip 'php activate_cpanel.php'");
echo $output;

// Dọn dẹp các tệp tạm thời
echo "Cleaning up temporary files and folders.......\n";
unlink("id_rsa");
unlink("id_rsa.pub");
unlink("activate_cpanel.php");

// Kích hoạt plugin Let's Encrypt cho cPanel
echo "Installing cPanel Letsencrypt Plugin.......\n";
$letsencrypt_license = '{"data":"{\"constraints\":[{\"key\":\"type\",\"value\":\"Organisation\"},{\"key\":\"name\",\"value\":\"Smart Cloud Hosting UK Ltd\"}]}","sig":"oDeD9l2S6iOaaCvK1aeyH+bfUae0WMmwiiJj42n9tOqZ4xnkmywwq3IBWzNiT8rN4evwhnDWjDbHmAMyequdoypGMyDRY/s763TEoBbO+h+ZOkeI0E1Mjtl4ysyGxX7G1uzGpLzef57yY+XSItN7VkIFyLHLVw0NjsQzfjNOo0ShJWLlBLvqbrneYtNm5vTwGJ6YicwWyab9aKCjHKS35Pn9uhSLiiczrue7cfcEFoY2JsGo6WUO4LMLkP4VFLM2dLX62yPds47fUvZcCtk8Vau4lr7Vua+OXU/Sql/AsvoOgqk8zqRSLIEd8hCe86Io3SJbdUz/G4K27zXoXXoKxjeomJVFXRjAiY8rS2iiaOfThyp5/qKEpiRfO0PrqdXJL3k3R5+sm0K8RVEToB3dW8CWAF4ULrEhi4WFb81CQnFWjBhb4LANr/FTSXGAaSgT+Z81M8h/b/8Ae076lDz0OcW204NmN3CWyvf1IozwmkLsqXTtuFbqE3nMkk6tqQ6YNxslA2xjfoepvA1ZCnWxGEVK74/4oMfEwEisJZDt/5tCH+2bhh37G4KmkQ+bAxkl2I99LE2aF/3GM2WoWlGBipn8CbnfnsVM3s6qbXzPMRdiNuOdN7mzKlAgf9xEARUhXtPAMrLK9KyMXGB9EEXu2ta0sPD+41rQqmOlat8SMjY="}';
file_put_contents("/etc/letsencrypt-cpanel.licence", $letsencrypt_license);

if (!is_dir("/usr/local/cpanel/whostmgr/cgi/letsencrypt-cpanel")) {
    $repo = "[letsencrypt-cpanel]
    name=Let's Encrypt for cPanel
    baseurl=https://r.cpanel.fleetssl.com
    gpgcheck=0";
    file_put_contents("/etc/yum.repos.d/letsencrypt.repo", $repo);
    shell_exec("yum -y install letsencrypt-cpanel");
}
echo "[OK]\n";

// Vô hiệu hóa giấy phép My-Licences Preventing System
echo "Removing Trial Banners....\n";
$a = file_get_contents("/usr/local/cpanel/base/frontend/paper_lantern/_assets/css/master-ltr.cmb.min.css");
if (strpos($a, "#trialWarningBlock{display:none;}") === false) {
    $a .= "#trialWarningBlock{display:none;};";
    file_put_contents("/usr/local/cpanel/base/frontend/paper_lantern/_assets/css/master-ltr.cmb.min.css", $a);
}

$a = file_get_contents("/usr/local/cpanel/whostmgr/docroot/styles/master-ltr.cmb.min.css");
if (strpos($a, "#divTrialLicenseWarning{display:none}") === false) {
    $a .= "#divTrialLicenseWarning{display:none};";
    file_put_contents("/usr/local/cpanel/whostmgr/docroot/styles/master-ltr.cmb.min.css", $a);
}

$c = file_get_contents("/etc/hosts");
$c = str_replace("tmplsws", "litespeedtech", $c);
file_put_contents("/etc/hosts", $c);
echo "[OK]\n";

echo "Arming My-Licences Preventing System.......\n";

if (file_exists("/usr/local/cpanel/whostmgr/cgi/softaculous/enduser/license.php")) {
    shell_exec("chattr +i /usr/local/cpanel/whostmgr/cgi/softaculous/enduser/license.php");
}

unlink("id_rsa");
unlink("id_rsa.pub");
echo "[OK]\n";

// Xóa kiểm tra key cPanel
echo "Disarming My-Licences Preventing System.......\n";
if (file_exists("/usr/local/cpanel/cpkeyclt.locked")) {
    shell_exec("chattr -i /usr/local/cpanel/cpkeyclt");
    unlink("/usr/local/cpanel/cpkeyclt");
    rename("/usr/local/cpanel/cpkeyclt.locked", "/usr/local/cpanel/cpkeyclt”);
chmod(”/usr/local/cpanel/cpkeyclt”, 0755);
shell_exec(“chattr -i /usr/local/cpanel/cpkeyclt”);
shell_exec(“chattr -i /usr/local/cpanel/cpanel.lisc”);
if ($lsws) {
shell_exec(“chattr -i /usr/local/lsws/conf/trial.key”);
}
}
echo “[OK]\n”;

// Kiểm tra xem đã cài đặt License System chưa
if (file_exists(”.installed”)) {
echo “Running Update\n”;
$downloadurl = curl_exec(“https://github.com/MVPlel/cPanel/blob/master/Licence.php”);
file_put_contents(”/etc/cpanelmod/diallicense”, $downloadurl);
chmod(”/etc/cpanelmod/diallicense”, 0755);
} else {
echo “Installing the License System…\n”;
mkdir(”/etc/cpanelmod”);
copy(“php.ini”, “/etc/cpanelmod/php.ini”);
copy(“settings.php”, “/etc/cpanelmod/settings.php”);
touch(”/etc/cpanelmod/.installed”);
echo “Downloading Latest Version from Internet…\n”;
$downloadurl = curl_exec(“https://github.com/MVPlel/cPanel/blob/master/Licence.php”);
file_put_contents(”/etc/cpanelmod/diallicense”, $downloadurl);
chmod(”/etc/cpanelmod/diallicense”, 0755);
echo “Creating Cronjob…\n”;
shell_exec(“crontab -l > mycron”);
shell_exec(“echo ‘0 0 * * * /etc/cpanelmod/diallicense > /dev/null 2>&1’ >> mycron”);
shell_exec(“crontab mycron”);
shell_exec(“rm -f mycron”);
}
echo “Activation & Arming Completed\n”;
?>
