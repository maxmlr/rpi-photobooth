<?php

// Ausgabe von einigen Debugausgaben mit mylog("Message"))
$DEBUG = 0;

// Zeitzone
date_default_timezone_set('Europe/Berlin');

// Auswertung von vstat für einen entfernten host
// gültige ssh-Verbindung mit public-key
// $vnstat_bin_dir = 'ssh myrouter vnstat --json';
// oder
// $vnstat_bin_dir = "echo userpassword|su -c 'ssh myrouter vnstat --json' username";
// default localhost
$vnstat_bin_dir = '/usr/local/bin/vnstat --json';

// Anzeige der Schnittstellennamen ändern
$iface_doreplace = true;
$iface_replace = [
  
    "wlan0" => "www",
    "wlan1" => "hotspot",
    "eth0" => "ethernet",
    
];

?>
