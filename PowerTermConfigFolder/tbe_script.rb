#!/usr/bin/ruby

# --------------------------------------------------------------------
# REQUIRED GEMS
# --------------------------------------------------------------------
require 'rubygems'
require 'hpricot'


# --------------------------------------------------------------------
# FUNCTION DEFINITIONS
# These are just used as some shortcuts so that I don't have to
# re-type all this code every time I want to do stuff.
# --------------------------------------------------------------------
# Used to log info to the scan.log file
def log_info(message)
  msg_to_log = "[tbe_script.rb] " + message
  cmd_to_run = "logger " + msg_to_log + " #Developer #Comment"
  `#{cmd_to_run}`
  msg_to_log = msg_to_log + "\n"
  File.open("/var/log/tbe_script.log","a") { |f| f.write(msg_to_log) }
end

# Used to run a command and log the *return value*
def run_and_log(command)
  log_info "|-[INFO]-[FUNCTION:run_and_log]-> Running command:  #{command}"
  result = system(command)
  log_info "|-[INFO]-[FUNCTION:run_and_log]-> Return Value: #{result}"
end

# Used to run a command and log the output
def run_and_log_output(command)
  log_info "|-[INFO]-[FUNCTION:run_and_log_output]-> Running command:  #{command}"
  result = `#{command}`
  log_info "|-[INFO]-[FUNCTION:run_and_log_output]-> Return Value: #{result}"
end


# Check if a file exists, and die if it is missing
def die_if_file_missing(filepath)
  if !File.exist? filepath
    log_info "|-[ERROR]-> Unable to locate a file: ${filepath}.  Exiting."
    exit
  end
end

# Used to notify the user that something is going on under the hood.
def notify_user (title, msg)
  log_info "|-[NOTIFICATION DISPLAYED]-> Title:\"#{title}\" Msg:\"#{msg}\""
  #Syntax: osascript -e 'display notification "message" with title "title"'
  #system(`osascript -e \'display notification \"#{msg}\" with title \"#{title}\"\'`)

  scpt = 'display notification "%s"' % msg
  scpt << ' with title "%s"' % title
  system %|osascript -e "#{scpt.gsub(/"/, '\"')}"|

end

# Used to sort the output of the scanner so that scans of 10 or more
# pages are properly coallated.
def sort_scanned_pages
  log_info "|-[INFO]-[FUNCTION:sort_scanned_pages]-> Sorting scanned pages"
  run_and_log "mv /tmp/lastscan.jpg /tmp/lastscan_00.jpg"
  if File.exist? "/tmp/lastscan_0.jpg"
    run_and_log "mv /tmp/lastscan_0.jpg /tmp/lastscan_00a.jpg"
  end
  if File.exist? "/tmp/lastscan_1.jpg"
    run_and_log "mv /tmp/lastscan_1.jpg /tmp/lastscan_01.jpg"
  end
  if File.exist? "/tmp/lastscan_2.jpg"
    run_and_log "mv /tmp/lastscan_2.jpg /tmp/lastscan_02.jpg"
  end
  if File.exist? "/tmp/lastscan_3.jpg"
    run_and_log "mv /tmp/lastscan_3.jpg /tmp/lastscan_03.jpg"
  end
  if File.exist? "/tmp/lastscan_4.jpg"
    run_and_log "mv /tmp/lastscan_4.jpg /tmp/lastscan_04.jpg"
  end
  if File.exist? "/tmp/lastscan_5.jpg"
    run_and_log "mv /tmp/lastscan_5.jpg /tmp/lastscan_05.jpg"
  end
  if File.exist? "/tmp/lastscan_6.jpg"
    run_and_log "mv /tmp/lastscan_6.jpg /tmp/lastscan_06.jpg"
  end
  if File.exist? "/tmp/lastscan_7.jpg"
    run_and_log "mv /tmp/lastscan_7.jpg /tmp/lastscan_07.jpg"
  end
  if File.exist? "/tmp/lastscan_8.jpg"
    run_and_log "mv /tmp/lastscan_8.jpg /tmp/lastscan_08.jpg"
  end
  if File.exist? "/tmp/lastscan_9.jpg"
    run_and_log "mv /tmp/lastscan_9.jpg /tmp/lastscan_09.jpg"
  end
end


# Used to remove blank scanned pages before a file is uploaded to TBE
def remove_blank_pages
  log_info "|----------------------------------------------"
  log_info "|-[INFO]->[FUNCTION:remove_blank_pages]-> Entering function"

  Dir.glob('/tmp/*.jpg').each do |file|
    log_info "|-[INFO]->[FUNCTION:remove_blank_pages]-> Evaluating #{file}\n"
    result = `/usr/local/bin/detect_blank_page #{file}`
    log_info "|-[INFO]->[FUNCTION:remove_blank_pages]-> Result: #{result}\n"
    if result.include? "blank"
      log_info "|-[INFO]-[FUNCTION:remove_blank_pages]-> Blank page detected. Removing file."
      run_and_log "rm #{file}"
    end
  end # of looping through the .jpg files in /tmp

end # of function remove_blank_pages


# --------------------------------------------------------------------
# --------------------------------------------------------------------
# --------------------------------------------------------------------
# ------------  END OF FUNCTION DEFINITION SECTION  ------------------
# --------------------------------------------------------------------
# --------------------------------------------------------------------
# --------------------------------------------------------------------


# Grab the message from the server and exit if it is nil
message_from_server = ARGV.first
if message_from_server.nil?
  log_info "|-[ERROR]-> ERROR: no data from server. Exiting."
  exit
end




# --------------------------------------------------------------------
# SCANNER CALL
# If we're passed a ".bsm" file, this means that this is a call to
# scan something with the attached scanner.
# --------------------------------------------------------------------
if message_from_server.include? ".bsm"
  # Log and track the start time
  start_time = Time.now
  log_info "|=============================================="
  log_info "|-[INFO]-> Scan initiated at #{start_time.to_s}"
  log_info "|----------------------------------------------"
  notify_user("Scan Starting","Scanner script starting up now.")

  # Log the message from the server prior to parsing it
  log_info "|-[INFO]-> Message from server was: #{message_from_server}"

  # Copy the config file to the local temp directory
  config_file = message_from_server.split("\\")[10]
  log_info "|-[INFO]-> Getting config file: #{config_file}"
  run_and_log "scp scanuser@10.0.1.100:/var/www/html/documentconnection/pages/TBEscan/#{config_file} /tmp/last_scan_config"

  # Open and parse the scan configuration file
  scan_config = File.open("/tmp/last_scan_config") { |f| Hpricot.XML(f) }
  resolution = scan_config.at("Resolution").inner_text.to_i
  colormode  = scan_config.at("PixelType").inner_text.to_i
    colormode = "Color" if colormode == 3
    colormode = "Color" if colormode == 2
    colormode = "Gray" if colormode == 1
    colormode = "Lineart" if colormode == 0
  format     = scan_config.at("ImageFormat").inner_text.downcase
  outfile    = scan_config.at("OutputFile").inner_text.split("\\")[5]
  webrequest = scan_config.at("WebRequest").inner_text
  log_info "|-[INFO]-[CONFIG_FILE]-> Resolution: #{resolution} dpi"
  log_info "|-[INFO]-[CONFIG_FILE]-> Format:     #{format}"
  log_info "|-[INFO]-[CONFIG_FILE]-> Outfile:    #{outfile}"
  log_info "|-[INFO]-[CONFIG_FILE]-> WebRequest: #{webrequest}"
  log_info "|-[INFO]-[CONFIG_FILE]-> Color Mode: #{colormode}"
  log_info "|----------------------------------------------"

  # Clean up any previously-scanned files
  log_info "|-[INFO]-> Cleaning up previously-scanned .pdf file from the /tmp directory"
  log_info "|----------------------------------------------"
  run_and_log "rm /tmp/lastscan*.*"

  # Run the scanline command to get the image
  #log_info "Running the scanline command now"
  run_and_log "/usr/local/bin/scanline -duplex -scanner \"EPSON DS-510\" -dir /tmp -resolution 150 -name lastscan -jpeg"

  die_if_file_missing("/tmp/lastscan.jpg")

  # call the sort_scanned_pages function to sort the individual files
  sort_scanned_pages

  # call the remove_blank_pages function to remove the blank pages
  remove_blank_pages

  # Convert the image and copy to the correct filename
  log_info "|----------------------------------------------"
  log_info "|-[INFO]-> Converting from .jpg to .tif with lzw compression"
  log_info "|----------------------------------------------"
  run_and_log "/opt/local/bin/convert -compress lzw /tmp/lastscan*.jpg /tmp/lastscan.tif"
  die_if_file_missing("/tmp/lastscan.tif")

  # Upload the file to the server
  notify_user("Uploading","Uploading the scanned file now.")
  run_and_log "scp /tmp/lastscan.tif scanuser@10.0.1.100:/var/www/html/documentconnection/pages/TBEscan/#{outfile}"

  # Remove the last scanned .tif
  run_and_log "rm /tmp/lastscan*.tif"

  system("open #{webrequest};")

  # Log the end time and total time taken.
  end_time = Time.now
  log_info "|----------------------------------------------"
  log_info "|-[INFO]-> Scan completed at #{end_time.to_s}"
  log_info "|=============================================="
  log_info ""

  exit
end


# --------------------------------------------------------------------
# OPEN URL CALL
# If the message from the server includes "http" then we need to open
# a URL.  This is handled with a simple system call then a forced exit
# from the script.
# --------------------------------------------------------------------
if message_from_server.include? "http"
  system("open \"#{message_from_server}\"")
  exit # force exit from the script
end


# --------------------------------------------------------------------
# OPEN SMB FILE CALL
# If the message from the server includes "\\" then we need to open a
# file that is shared from the server via SMB.  Note that .bsm files
# have already been screened out so there are no conflicts with
# the server's message.
# --------------------------------------------------------------------
if message_from_server.include? "\\"
  # We need to open a file on an SMB share
  # First parse out what was passed
  components = message_from_server.split("\\")
  ip         = components[4]
  share      = components[6]
  file       = components[8]

  if !File.directory?("/Volumes/#{share}")
    # The volume is not mounted, so mount it
    exec "open smb://#{ip}/#{share}"
  end

  exec "open /Volumes/#{share}/#{file}"

  exit # force exit from the script
end
