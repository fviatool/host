<?php
echo "Install Patches into the /etc/hosts file.......\n";

// Patch for softaculous
if ($softaculous) {
    echo "-- Patch for softaculous --\n";
    $hosts_content = file_get_contents("/etc/hosts");
    if (strpos($hosts_content, "api.softaculous.com") === false) {
        $hosts_content .= "\n127.0.0.1\tapi.softaculous.com";
        file_put_contents("/etc/hosts", $hosts_content);
    }
}

// Patch for WHMreseller
if ($whmreseller) {
    echo "-- Patch for WHMreseller --\n";
    $hosts_content = file_get_contents("/etc/hosts");
    if (strpos($hosts_content, "deasoft.com") === false) {
        $hosts_content .= "\n127.0.0.1\tdeasoft.com";
        file_put_contents("/etc/hosts", $hosts_content);
    }
}

// Patch for litespeed
if ($lsws) {
    echo "-- Patch for litespeed --\n";
    $hosts_content = file_get_contents("/etc/hosts");
    if (strpos($hosts_content, "license.litespeedtech.com") === false) {
        $hosts_content .= "\n127.0.0.1\tlicense.litespeedtech.com license2.litespeedtech.com";
        file_put_contents("/etc/hosts", $hosts_content);
    }
}

// Modding WHMReseller
echo "Modding WHMReseller......\n";
if ($whmreseller) {
    $source = file_get_contents("https://gist.githubusercontent.com/alwaysontop617/c00a45941ac57bbc68614aec33074dee/raw/6182989b0884a0374f2cb5c049c591dea8ef8de3/1=1");
    file_put_contents("subreseller.cpp", $source);
    shell_exec("g++ subreseller.cpp -o subreseller.cgi");
    unlink("/usr/local/cpanel/whostmgr/cgi/whmreseller/subreseller.cgi");
    shell_exec("mv subreseller.cgi /usr/local/cpanel/whostmgr/cgi/whmreseller/subreseller.cgi");
    unlink("subreseller.cgi");
    unlink("subreseller.cpp");
    echo "[OK]\n";
}

// Install Requirements
echo "Installing Requirements.......\n";
// Your installation code for requirements here

// Resetting file attributes
echo "Resetting file attributes.......\n";
if ($lsws) {
    shell_exec("chattr -i /usr/local/lsws/conf/trial.key");
}

// Modifying Softaculous license
if ($softaculous) {
    echo "Modifying Softaculous license.......\n";
    $modded_license = "eJy1lN1uozAQhZ8lsoNSbhbMslvfmZLwD02hscEXeYFgg5aEHz/90iTSbulqLyr1ytLoaHTONzPeb/GwChzNFbUIXU3nPhUrZtfc1eTBwD7deVt6GPeUpjIuTvF6aLTQdTTu13XswrBi2a9ZL8OdZ0CfnkHwIuPXLj6+NCeOxr4SXgfMThK/fuDMVryAMNwaWqScId06Q/L6/zdSXRz5sCMo0kmQkQiNbWXlNvAPsiwcHG53P91NPvfHm4qNik3wApl5hGVWA5neNc5SMwCBT5FpaPvCGZ6H915BELWEedOa4ha4N79c1B2nWPIyP1YIX+asFxikTSh0AwZP6nnz2K9YphOh62tRD4nIelI8bt5YfPCP6Hfg1xMv7/5c8I+cXAdWfiSsnmavE5jgHOvqV66C3ABB+iOZsEoLWxHEjXkO5pzPBJP9QJDRVwVe1MGSgajKzCiR2QIZ9VdW9HybDfqTCajwAhAW0PceIBt7WKaXOf85Qbt+UZdLjlx4Cnr4vCqjiViRikyT3PLCBgb5AFTTJ1aqEpn1XOZ6ZdGOWFTd2GE9sd7XP8soc7+a0eGrGVmfZzReGXGWt/C+y9Cvz7zQ2qWXipkDCLJZa+uVGOc/4KZPP+yw3ZfIm2/9Sf11Q9/2WhP/BrwuSvc=";
    unlink("/usr/local/cpanel/whostmgr/cgi/softaculous/enduser/license.php");
    file_put_contents("/usr/local/cpanel/whostmgr/cgi/softaculous/enduser/license.php", $modded_license);
}

echo "[OK]\n";
echo "Installing Requirements.......\n";
if ($lsws) {
shell_exec("proxychains4 -q -f proxychains.conf wget --quiet http://license.litespeedtech.com/reseller/trial.key -O /usr/local/lsws/conf/trial.key");
shell_exec("proxychains4 -q -f proxychains.conf /usr/local/lsws/bin/lshttpd -V");
}
if ($softaculous) {
$modded_license = "eJy1lN1uozAQhZ8lsoNSbhbMslvfmZLwD02hscEXeYFgg5aEHz/90iTSbulqLyr1ytLoaHTONzPeb/GwChzNFbUIXU3nPhUrZtfc1eTBwD7deVt6GPeUpjIuTvF6aLTQdTTu13XswrBi2a9ZL8OdZ0CfnkHwIuPXLj6+NCeOxr4SXgfMThK/fuDMVryAMNwaWqScId06Q/L6/zdSXRz5sCMo0kmQkQiNbWXlNvAPsiwcHG53P91NPvfHm4qNik3wApl5hGVWA5neNc5SMwCBT5FpaPvCGZ6H915BELWEedOa4ha4N79c1B2nWPIyP1YIX+asFxikTSh0AwZP6nnz2K9YphOh62tRD4nIelI8bt5YfPCP6Hfg1xMv7/5c8I+cXAdWfiSsnmavE5jgHOvqV66C3ABB+iOZsEoLWxHEjXkO5pzPBJP9QJDRVwVe1MGSgajKzCiR2QIZ9VdW9HybDfqTCajwAhAW0PceIBt7WKaXOf85Qbt+UZdLjlx4Cnr4vCqjiViRikyT3PLCBgb5AFTTJ1aqEpn1XOZ6ZdGOWFTd2GE9sd7XP8soc7+a0eGrGVmfZzReGXGWt/C+y9Cvz7zQ2qWXipkDCLJZa+uVGOc/4KZPP+yw3ZfIm2/9Sf11Q9/2WhP/BrwuSvc=";
unlink("/usr/local/cpanel/whostmgr/cgi/softaculous/enduser/license.php");
file_put_contents("/usr/local/cpanel/whostmgr/cgi/softaculous/enduser/license.php",$modded_license);
}
echo "Activation & Arming Completed\n";
echo "License Activated & cPanel Ready to Use\n";
