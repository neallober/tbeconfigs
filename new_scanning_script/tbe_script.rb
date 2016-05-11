#!/usr/bin/ruby

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
  log_info "|-[INFO]-[FUNCTION:run_and_log]-> Running command: #{command}"
  result = system(command)
  log_info "|-[INFO]-[FUNCTION:run_and_log]-> Return Value: #{result}"
end


# --------------------------------------------------------------------
# SCRIPT FUNCTIONALITY IS BELOW
# --------------------------------------------------------------------
message_from_server = ARGV.first
if message_from_server.nil?
  log_info "|-[ERROR]-> ERROR: no data from server. Exiting."
  exit
else
  log_info "|-[INFO]-> Message from server was: #{message_from_server}"
end

if message_from_server.include? "bsm"
  log_info "|-[INFO]-> BSM file passed.  Going to start the scanner application..."
  # Copy the config file to the local temp directory
  config_file = message_from_server.split("\\")[10]
  log_info "|-[INFO]-> Getting config file: #{config_file}"
  run_and_log "scp scanuser@10.0.1.100:/var/www/html/documentconnection/pages/TBEscan/#{config_file} /tmp/last_scan_config.bsm"
  run_and_log "open -n /Applications/ScannerApp.app --args \"/tmp/last_scan_config.bsm\" silent"
  exit # force exit from the script

else
  log_info "|-[INFO]-> No BSM file passed.  Going to open a URL..."
  run_and_log "open \"#{message_from_server}\""
  exit # force exit from the script

end
