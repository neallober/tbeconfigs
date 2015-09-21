#!/bin/bash

echo "patch.sh - Setup workstation for The Business Edge"
echo "..."
echo "Administrator password required to continue"
# Ask for the administrator password upfront.
sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Setup login window message
echo "Setting up login window message..."
sudo /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow.plist LoginwindowText "Allied Fasteners secured workstation. Access controlled. Use of this computer is governed by the company Acceptable Use Policy."
sudo /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool true
sudo /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow showInputMenu -bool true

# Set screensaver lock settings
echo "Setting screensaver settings..."
sudo /usr/bin/defaults write "/System/Library/User Template/English.lproj/Library/Preferences/com.apple.screensaver" askForPasswordDelay -string 60
sudo /usr/bin/defaults write "/System/Library/User Template/English.lproj/Library/Preferences/com.apple.screensaver" askForPassword -int 1

# Patch TBE4
echo "Checking for TBE4 on this computer..."
if [ -e /Applications/The\ Business\ Edge.app/Contents/Resources/app.nw/bin/scanimage.php ]; then
  echo "[+] TBE4 found! Patching now..."
  sudo curl -fsSL https://github.com/neallober/tbeconfigs/blob/master/TBE4/detect_blank_page.sh > /tmp/detect_blank_page.sh
  sudo chmod 755 /tmp/detect_blank_page.sh
  sudo mv /tmp/detect_blank_page.sh /usr/local/bin/detect_blank_page.sh
  sudo curl -fsSL https://raw.githubusercontent.com/neallober/tbeconfigs/master/TBE4/scanimage.php > /tmp/scanimage.php
  sudo chmod 755 /tmp/scanimage.php
  sudo mv /tmp/scanimage.php /Applications/The\ Business\ Edge.app/Contents/Resources/app.nw/bin/scanimage.php
fi

# Patch PowerTerm install
echo "Checking for PowerTerm on this computer..."
if [ -e /Applications/PowerTerm/PowerTerm.app/Contents/Info.plist ]; then
  echo "[+] PowerTerm found! Patching now..."
fi
