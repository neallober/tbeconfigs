#!/bin/bash

echo "__________________________________________________"
echo "patch.sh - Setup workstation for The Business Edge"
echo "__________________________________________________"
echo "[ ] Administrator password required to continue"
# Ask for the administrator password upfront.
sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Setup login window message
echo "[ ] Setting up login window message..."
sudo /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow.plist LoginwindowText "Allied Fasteners secured workstation. Access controlled. Use of this computer is governed by the company Acceptable Use Policy."
sudo /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool true
sudo /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow showInputMenu -bool true

# Set screensaver lock settings
echo "[ ] Setting screensaver settings..."
sudo /usr/bin/defaults write "/System/Library/User Template/English.lproj/Library/Preferences/com.apple.screensaver" askForPasswordDelay -string 60
sudo /usr/bin/defaults write "/System/Library/User Template/English.lproj/Library/Preferences/com.apple.screensaver" askForPassword -int 1

# Patch TBE4
echo "[ ] Checking for TBE4 on this computer..."
if [ -e /Applications/The\ Business\ Edge.app/Contents/Resources/app.nw/bin/scanimage.php ]; then
  echo "[+] TBE4 found! Patching now..."
  sudo curl -fsSL http://github.com/neallober/tbeconfigs/blob/master/TBE4/detect_blank_page.sh > /tmp/detect_blank_page.sh
  sudo chmod 755 /tmp/detect_blank_page.sh
  sudo mv /tmp/detect_blank_page.sh /usr/local/bin/detect_blank_page.sh
  sudo curl -fsSL http://raw.githubusercontent.com/neallober/tbeconfigs/master/TBE4/scanimage.php > /tmp/scanimage.php
  sudo chmod 755 /tmp/scanimage.php
  sudo mv /tmp/scanimage.php /Applications/The\ Business\ Edge.app/Contents/Resources/app.nw/bin/scanimage.php
fi

# Patch PowerTerm install
echo "[ ] Checking for PowerTerm on this computer..."
if [ -e /Applications/PowerTerm/PowerTerm.app/Contents/Info.plist ]; then
  echo "[+] PowerTerm application found!"

  # Make sure that the ~/PowerTermConfigFolder directory exists
  if [ -d "$HOME/PowerTermConfigFolder" ]; then
    echo "[ ] PowerTermConfigFolder exists at $HOME/PowerTermConfigFolder"
  else
    echo "[ ] PowerTermConfigFolder does not exist. Creating directory now."
    mkdir $HOME/PowerTermConfigFolder
  fi

  # Download the config files from github
  echo "" > $HOME/PowerTermConfigFolder/Getting
  echo "" > $HOME/PowerTermConfigFolder/MailToEricom1.txt
  echo "" > $HOME/PowerTermConfigFolder/Message
  echo "" > $HOME/PowerTermConfigFolder/Return
  echo "" > $HOME/PowerTermConfigFolder/Running
  curl -fsSL http://raw.githubusercontent.com/neallober/tbeconfigs/master/PowerTermConfigFolder/TBEm-off.psl > $HOME/PowerTermConfigFolder/TBEm-off.psl
  curl -fsSL http://raw.githubusercontent.com/neallober/tbeconfigs/master/PowerTermConfigFolder/TBEm-on.psl  > $HOME/PowerTermConfigFolder/TBEm-on.psl
  curl -fsSL http://raw.githubusercontent.com/neallober/tbeconfigs/master/PowerTermConfigFolder/pt.cfg       > $HOME/PowerTermConfigFolder/pt.cfg
  curl -fsSL http://raw.githubusercontent.com/neallober/tbeconfigs/master/PowerTermConfigFolder/ptcomm.ini   > $HOME/PowerTermConfigFolder/ptcomm.ini
  curl -fsSL http://raw.githubusercontent.com/neallober/tbeconfigs/master/PowerTermConfigFolder/ptdef.ptc    > $HOME/PowerTermConfigFolder/ptdef.ptc
  curl -fsSL http://raw.githubusercontent.com/neallober/tbeconfigs/master/PowerTermConfigFolder/ptdef.ptk    > $HOME/PowerTermConfigFolder/ptdef.ptk
  curl -fsSL http://raw.githubusercontent.com/neallober/tbeconfigs/master/PowerTermConfigFolder/ptdef.ptp    > $HOME/PowerTermConfigFolder/ptdef.ptp
  curl -fsSL http://raw.githubusercontent.com/neallober/tbeconfigs/master/PowerTermConfigFolder/ptdef.ptr    > $HOME/PowerTermConfigFolder/ptdef.ptr
  curl -fsSL http://raw.githubusercontent.com/neallober/tbeconfigs/master/PowerTermConfigFolder/ptdef.pts    > $HOME/PowerTermConfigFolder/ptdef.pts
  curl -fsSL http://raw.githubusercontent.com/neallober/tbeconfigs/master/PowerTermConfigFolder/ptdef.ptx    > $HOME/PowerTermConfigFolder/ptdef.ptx
  curl -fsSL http://raw.githubusercontent.com/neallober/tbeconfigs/master/PowerTermConfigFolder/tbe.psl      > $HOME/PowerTermConfigFolder/tbe.psl

  echo "[ ] PowerTerm configuration complete."
fi
