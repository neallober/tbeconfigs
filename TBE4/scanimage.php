#!/usr/bin/php
<?php
###############################################################
# Script to handle scanning images and uploading to TBE server
#
# As of 8/27/2014, scanline is hosted at:
# https://github.com/klep/scanline
###############################################################
# Installation Notes
#
# 1. Make sure that imagemagick is installed (brew install imagemagick)
# 2. Make sure that scanline is installed
# 3. Verify command paths are set up correctly
# 4. Verify the scanner name and adjust if necessary (-scanner \"EPSON DS-510\")
#
###############################################################


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

# Handle writing a message to the os x system log (can be seen in Console.app)
function log_message($msg){
    $backtrace = debug_backtrace();
    $calling_line = $backtrace[1]['line'];
    syslog(1, "[scanimage.php ln=${calling_line}] $msg ");
}

# Check if a function exists. Use this to catch missing packages.
function command_exist($cmd) {
    $returnVal = shell_exec("which $cmd");
    return (empty($returnVal) ? false : true);
}



###############################################################
# CHECK FOR DEPENDENCIES
###############################################################
$start_timestamp = exec("date");
log_message("************************************************");
log_message("* scanimage.php script starting                *");
log_message("* $start_timestamp");
log_message("************************************************");

# Check for missing packages / dependencies.
if (!command_exist('/usr/local/bin/convert')) {
    notifyuser("Missing ImageMagick","ImageMagick is not installed on this computer.");
    exit;
}
if (!command_exist('/usr/local/bin/scanline')) {
    notifyuser("Missing scanline","The scanline package is not installed on this computer.");
    exit;
}

# Assuming the convert and scanline commands are found, we are good to go.
# Let the user know that we will start the scanning process.
notifyuser("Starting Scan","Starting your scan now. Please be patient.");

# Make sure we have a config file
if(!isset($argv[1])){
    notifyuser("Error - No config file","Unable to scan without a config file.");
    echo "Purpose\t: Handle scanning images on mac/linux\n";
    echo "Syntax\t: scanimage.php  \"<config.bsm>\"\n";
    echo "Flags\t: -w\t Load the WebRequest url in the background\n";
    log_message("* No configuration file available.  Exiting.");
    exit;
}

# Set if we want the webRequest URL loaded in foreground or background
$loadbackground = (strtolower($argv[2])=="-w"||strtolower($argv[3])=="-w") ? 1 : 0;
log_message("* loadbackground is set to $loadbackground");

# Load up the config and set some options
$xml = @simplexml_load_file($argv[1]) or die("bsm config file not found\n") ;
$cfg = $xml->Twain;
log_message("* Configuration variable set");
log_message("* cfg->UnixFile = {$cfg->UnixFile}");
log_message("* cfg->UnixDir = {$cfg->UnixDir}");
log_message("* cfg->UnixUrl = {$cfg->UnixUrl}");
log_message("* cfg->WebRequest = {$cfg->WebRequest}");

# Run the scanline command
log_message("* Running the scanline command now");
$scanlog = my_exec("/usr/local/bin/scanline -duplex -scanner \"EPSON DS-510\" -dir /tmp -resolution 150 -name lastscan -jpeg");

# Detect some common errors and display messages to user
if(!file_exists('/tmp/lastscan.jpg')){
    log_message("* Error: unable to locate a file named /tmp/lastscan.jpg. Exiting.");
    $error = "Unable to locate the scanned file.  Please call Neal for support.";
    die("Error Scanning: " . $error . "\n");
}

# Sort the files in the directory so that conversion will retain coallation
my_exec("mv /tmp/lastscan.jpg /tmp/lastscan_00.jpg");
if(file_exists('/tmp/lastscan_0.jpg')){my_exec("mv /tmp/lastscan_0.jpg /tmp/lastscan_00a.jpg");}
  # at this point we will have lastscan_00.jpg, _00a.jpg; going on to add_01, _02, etc...
if(file_exists('/tmp/lastscan_1.jpg')){my_exec("mv /tmp/lastscan_1.jpg /tmp/lastscan_01.jpg");}
if(file_exists('/tmp/lastscan_2.jpg')){my_exec("mv /tmp/lastscan_2.jpg /tmp/lastscan_02.jpg");}
if(file_exists('/tmp/lastscan_3.jpg')){my_exec("mv /tmp/lastscan_3.jpg /tmp/lastscan_03.jpg");}
if(file_exists('/tmp/lastscan_4.jpg')){my_exec("mv /tmp/lastscan_4.jpg /tmp/lastscan_04.jpg");}
if(file_exists('/tmp/lastscan_5.jpg')){my_exec("mv /tmp/lastscan_5.jpg /tmp/lastscan_05.jpg");}
if(file_exists('/tmp/lastscan_6.jpg')){my_exec("mv /tmp/lastscan_6.jpg /tmp/lastscan_06.jpg");}
if(file_exists('/tmp/lastscan_7.jpg')){my_exec("mv /tmp/lastscan_7.jpg /tmp/lastscan_07.jpg");}
if(file_exists('/tmp/lastscan_8.jpg')){my_exec("mv /tmp/lastscan_8.jpg /tmp/lastscan_08.jpg");}
if(file_exists('/tmp/lastscan_9.jpg')){my_exec("mv /tmp/lastscan_9.jpg /tmp/lastscan_09.jpg");}

# Store a copy of the source files in the /tmp/last_scan_files directory
my_exec("rm /tmp/last_scan_files/*.jpg");
my_exec("cp /tmp/lastscan_*.jpg /tmp/last_scan_files/");

# Check for blank pages and rename them so they won't be included in the file sent to TBE
notifyuser("Removing Blanks","Detecting and removing blank pages.");
log_message("*  *Checking all scanned .jpg files to remove blank pages");

# Loop through each .jpg in the /tmp directory and remove it if it's a blank page.
$handle = opendir('/tmp');
while (false !== ($file = readdir($handle))) {
  $extension = strtolower(substr(strrchr($file, '.'), 1));
  if($extension == 'jpg') {
    #echo(" -> Found a jpg: ${file}\n");
    log_message("* [Evaluating for blank: /tmp/${file}]");
    $retval = my_exec("/usr/local/bin/detect_blank_page.sh /tmp/${file}");
    log_message("*  *Returned value ${retval}]");
    if (strpos($retval,'blank') !== false){
      log_message("*  *  *Removing blank file: /tmp/${file}");
      my_exec("rm /tmp/${file}"); // blank page detected, remove it
    } else {
      log_message("* *  *Leaving file alone, not blank: /tmp/${file}");
    }
  }
}

# Convert the image and copy to the correct filename
log_message("* Converting from .jpg to .tif with lzw compression");
$convertlog = my_exec("/opt/local/bin/convert -compress lzw -units PixelsPerInch /tmp/lastscan*.jpg -density 150 -colorspace Gray /tmp/lastscan.tif");

# Detect some common errors and display messages to user
if(!file_exists('/tmp/lastscan.tif')){
    log_message("* Error: unable to locate a file named /tmp/lastscan.tif. Exiting.");
    $error = "Unable to locate the scanned file.  Please call Neal for support.";
    die("Error Scanning: " . $error . "\n");
}

# Copying the lastscan.tif file to whatever filename TBE is expecting
log_message("* Copying the file from /tmp/lastscan.tif to /tmp/{$cfg->UnixFile}");
system("cp /tmp/lastscan.tif /tmp/{$cfg->UnixFile}");

notifyuser("Uploading","Floating your pixels up to the cloud.");

# Upload the file
$data = array("destdir"=>$cfg->UnixDir,"file"=>"@/tmp/{$cfg->UnixFile}");
log_message("* Preparing to use curl to send the file.  data is set to $data");
$ch = curl_init($cfg->UnixUrl);
log_message("* Result of curl_init is $ch");
curl_setopt($ch, CURLOPT_POST, 1);
curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, 1);
curl_setopt($ch, CURLOPT_HEADER, 0);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
log_message("* Running curl_exec now. Arguments passed are $ch");
$upload = curl_exec($ch);
log_message("* curl_exec returned $upload");

# Detect any errors uploading the file
log_message("* Checking for errors with the upload");
if(trim($upload) != "SUCCESS"){
    log_message("* Error detected uploading the file.");
    die("Error Uploading File: Please call Computer Insights!\n{$upload}");
}

# Remove the temp files.  If they are not removed, then future
# scans may have unintended pages appended.
log_message("* Removing the .tif file that was sent to the server from the /tmp directory");
exec("rm -f /tmp/{$cfg->UnixFile}");
log_message("* Removing the source .jpg files from the /tmp directory");
exec("rm -f /tmp/lastscan*.jpg");

# Handle loading the WebRequest URL in either foreground or backround
if($loadbackground){
    log_message("* Loading the WebRequest URL in the background");
    # Request the url in the background using CURL
	curl_setopt($ch, CURLOPT_URL, $cfg->WebRequest);
    $webrequest = curl_exec($ch);
} else {
    log_message("* Loading the WebRequest URL in the default browser");
    # Request the url in the OS default browser
    exec("open {$cfg->WebRequest}");
}

$end_timestamp = exec("date");
log_message("************************************************");
log_message("* scanimage.php script ending                  *");
log_message("* $end_timestamp");
log_message("************************************************");

?>
