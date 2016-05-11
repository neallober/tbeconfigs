#!/usr/bin/php
<?php

# Set error reporting and flag to readin characters as typed
error_reporting(E_ERROR | E_WARNING | E_PARSE);
system("stty -icanon");


###############################################################
# Function Definitions
###############################################################

# Handle running a process and including stderr in stdout
function my_exec($cmd) {
    $proc=proc_open($cmd, array(0=>array('pipe','r'), 1=>array('pipe','w'), 2=>array('pipe','w')), $pipes);
    $stdout=stream_get_contents($pipes[1]);fclose($pipes[1]);
    $stdout.=stream_get_contents($pipes[2]);fclose($pipes[2]);
    $rtn=proc_close($proc);
    return $stdout;
}

# Notifications to provide the user with some feedback as to what's going on.
function notifyuser($title,$msg) {
    exec("osascript -e 'display notification \"${msg}\" with title \"${title}\"'");
}

# Check if a function exists. Use this to catch missing packages.
function command_exist($cmd) {
    $returnVal = shell_exec("which $cmd");
    return (empty($returnVal) ? false : true);
}


###############################################################
# Call the Scanning App
###############################################################

my_exec("logger BSM file located at: $argv[1]");
my_exec("logger Calling the scanning app now");
my_exec("open -n /Applications/ScannerApp.app --args \"$argv[1]\" silent");

?>
