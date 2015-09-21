#!/bin/bash

echo "__________________________________________________"
echo "patch.sh - Setup workstation for TBE"
echo "__________________________________________________"
echo "Administrator password required to continue"

# Ask for the administrator password upfront.
sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &




# Ask if the user wants to set up the workstation prefs
echo -n "Setup general workstation preferences? [y/n]: "
read -n 1 generalsetup
echo ""

if [ "$generalsetup" == "y" ]; then
  # Setup login window message
  echo "[ ] Setting up login window message..."
  sudo /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow.plist LoginwindowText "Allied Fasteners secured workstation. Access controlled. Use of this computer is governed by the company Acceptable Use Policy."
  sudo /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool true
  sudo /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow showInputMenu -bool true

  # Set screensaver lock settings
  echo "[ ] Setting screensaver settings..."
  sudo /usr/bin/defaults write "/System/Library/User Template/English.lproj/Library/Preferences/com.apple.screensaver" askForPasswordDelay -string 60
  sudo /usr/bin/defaults write "/System/Library/User Template/English.lproj/Library/Preferences/com.apple.screensaver" askForPassword -int 1

  # Check for brew
  if hash brew 2>/dev/null; then
    echo "[ ] brew utility already installed on this computer."
  else
    echo "[ ] Installing brew."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi

  if hash convert 2>/dev/null; then
    echo "[ ] ImageMagick is already installed."
  else
    echo "[ ] Installing ImageMagick via brew now..."
    brew install imagemagick
  fi

  if hash mtr 2>/dev/null; then
    echo "[ ] mtr is already installed."
  else
    echo "[ ] Installing mtr via brew now..."
    brew install mtr
  fi

  if hash speedtest-cli 2>/dev/null; then
    echo "[ ] speedtest-cli is already installed."
  else
    echo "[ ] Installing speedtest-cli via brew now..."
    brew install speedtest-cli
  fi

  if hash ssh-copy-id 2>/dev/null; then
    echo "[ ] ssh-copy-id is already installed."
  else
    echo "[ ] Installing ssh-copy-id via brew now..."
    brew install ssh-copy-id
  fi

  if hash archey 2>/dev/null; then
    echo "[ ] archey is already installed."
  else
    echo "[ ] Installing archey via brew now..."
    brew install archey
  fi

  echo "[ ] Updating brew and upgrading all librarires."
  brew update
  brew upgrade

  echo "[ ] Configuring remote access"
  ARD="/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart"
  # Switch on Apple Remote Desktop
  sudo $ARD -configure -activate

  # Configure ARD access for the localadmin user
  sudo $ARD -configure -access -on
  sudo $ARD -configure -allowAccessFor -specifiedUsers
  sudo $ARD -configure -access -on -users localadmin -privs -all

  # Enable SSH
  sudo systemsetup -setremotelogin on

  # Disable iCloud for logging in users
  osvers=$(sw_vers -productVersion | awk -F. '{print $2}')
  sw_vers=$(sw_vers -productVersion)

  for USER_TEMPLATE in "/System/Library/User Template"/*
  	do
      sudo /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant DidSeeCloudSetup -bool TRUE
      sudo /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant GestureMovieSeen none
      sudo /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant LastSeenCloudProductVersion "${sw_vers}"
      sudo /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant LastSeenBuddyBuildVersion "${sw_build}"
  	done

  for USER_HOME in /Users/*
  	do
  		USER_UID=`basename "${USER_HOME}"`
  		if [ ! "${USER_UID}" = "Shared" ]; then
  		if [ ! -d "${USER_HOME}"/Library/Preferences ]; then
  			sudo mkdir -p "${USER_HOME}"/Library/Preferences
  			sudo chown "${USER_UID}" "${USER_HOME}"/Library
  			sudo chown "${USER_UID}" "${USER_HOME}"/Library/Preferences
  		fi
  		if [ -d "${USER_HOME}"/Library/Preferences ]; then
  			sudo /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant DidSeeCloudSetup -bool TRUE
  			sudo /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant GestureMovieSeen none
  			sudo /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant LastSeenCloudProductVersion "${sw_vers}"
  			sudo /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant LastSeenBuddyBuildVersion "${sw_build}"
  			sudo chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant.plist
  		fi
  	fi
  done

else
  echo "[!] Skipping workstation setup..."
fi




# Ask if the user wants to set up the workstation prefs
echo -n "Setup TBE & PowerTerm? [y/n]: "
read -n 1 tbesetup
echo ""

if [ "$tbesetup" == "y" ]; then
  # Patch TBE4
  echo "[ ] Checking for TBE4 on this computer..."
  if [ ! -e /Applications/The\ Business\ Edge.app/Contents/Resources/app.nw/bin/scanimage.php ]; then
    echo -n "[ ] TBE4 not detected on this computer. Install now? [y/n]: "
    read -n 1 install_tbe
    echo ""
    if [ "$install_tbe" == "y" ]; then
      echo "[ ] Downloading TBE4 now. Please wait..."
      curl -L# http://10.0.1.100/tbe4/tbe4.dmg > /tmp/tbe4.dmg
      echo "[ ] Opening .dmg file. Press enter when TBE4 dragged into Applications folder. [Enter]: "
      open /tmp/tbe4.dmg
      read -n 1 key
    else
      echo "[!] Skipping TBE4 download & installation."
    fi
  fi

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

    for USER_HOME in /Users/*
    	do
    		USER_UID=`basename "${USER_HOME}"`
    		if [[ ! "${USER_UID}" = "Shared" && ! "${USER_UID}" = "Guest" ]]; then
          # Make sure that the ~/PowerTermConfigFolder directory exists
      		if [ ! -d "${USER_HOME}"/PowerTermConfigFolder ]; then
            echo "[ ] PowerTermConfigFolder does not exist at ${USER_HOME}/PowerTermConfigFolder. Creating directory now."
      			sudo mkdir -p "${USER_HOME}"/PowerTermConfigFolder
      			sudo chown "${USER_UID}" "${USER_HOME}"/PowerTermConfigFolder
          else
            echo "[ ] PowerTermConfigFolder exists at ${USER_HOME}/PowerTermConfigFolder"
      		fi

          # Download the config files from github
          echo "[ ] Downloading PowerTerm config files from github for user ${USER_UID}"
          sudo echo "" > $USER_HOME/PowerTermConfigFolder/Getting
          sudo chown "${USER_UID}" "${USER_HOME}"/PowerTermConfigFolder/Getting
          sudo echo "" > $USER_HOME/PowerTermConfigFolder/MailToEricom1.txt
          sudo chown "${USER_UID}" "${USER_HOME}"/PowerTermConfigFolder/MailToEricom1.txt
          sudo echo "" > $USER_HOME/PowerTermConfigFolder/Message
          sudo chown "${USER_UID}" "${USER_HOME}"/PowerTermConfigFolder/Message
          sudo echo "" > $USER_HOME/PowerTermConfigFolder/Return
          sudo chown "${USER_UID}" "${USER_HOME}"/PowerTermConfigFolder/Return
          sudo echo "" > $USER_HOME/PowerTermConfigFolder/Running
          sudo chown "${USER_UID}" "${USER_HOME}"/PowerTermConfigFolder/Running
          sudo curl -fsSL http://raw.githubusercontent.com/neallober/tbeconfigs/master/PowerTermConfigFolder/TBEm-off.psl > $USER_HOME/PowerTermConfigFolder/TBEm-off.psl
          sudo chown "${USER_UID}" "${USER_HOME}"/PowerTermConfigFolder/TBEm-off.psl
          sudo curl -fsSL http://raw.githubusercontent.com/neallober/tbeconfigs/master/PowerTermConfigFolder/TBEm-on.psl  > $USER_HOME/PowerTermConfigFolder/TBEm-on.psl
          sudo chown "${USER_UID}" "${USER_HOME}"/PowerTermConfigFolder/TBEm-on.psl
          sudo curl -fsSL http://raw.githubusercontent.com/neallober/tbeconfigs/master/PowerTermConfigFolder/pt.cfg       > $USER_HOME/PowerTermConfigFolder/pt.cfg
          sudo chown "${USER_UID}" "${USER_HOME}"/PowerTermConfigFolder/pt.cfg
          sudo curl -fsSL http://raw.githubusercontent.com/neallober/tbeconfigs/master/PowerTermConfigFolder/ptcomm.ini   > $USER_HOME/PowerTermConfigFolder/ptcomm.ini
          sudo chown "${USER_UID}" "${USER_HOME}"/PowerTermConfigFolder/ptcomm.ini
          sudo curl -fsSL http://raw.githubusercontent.com/neallober/tbeconfigs/master/PowerTermConfigFolder/ptdef.ptc    > $USER_HOME/PowerTermConfigFolder/ptdef.ptc
          sudo chown "${USER_UID}" "${USER_HOME}"/PowerTermConfigFolder/ptdef.ptc
          sudo curl -fsSL http://raw.githubusercontent.com/neallober/tbeconfigs/master/PowerTermConfigFolder/ptdef.ptk    > $USER_HOME/PowerTermConfigFolder/ptdef.ptk
          sudo chown "${USER_UID}" "${USER_HOME}"/PowerTermConfigFolder/ptdef.ptk
          sudo curl -fsSL http://raw.githubusercontent.com/neallober/tbeconfigs/master/PowerTermConfigFolder/ptdef.ptp    > $USER_HOME/PowerTermConfigFolder/ptdef.ptp
          sudo chown "${USER_UID}" "${USER_HOME}"/PowerTermConfigFolder/ptdef.ptp
          sudo curl -fsSL http://raw.githubusercontent.com/neallober/tbeconfigs/master/PowerTermConfigFolder/ptdef.ptr    > $USER_HOME/PowerTermConfigFolder/ptdef.ptr
          sudo chown "${USER_UID}" "${USER_HOME}"/PowerTermConfigFolder/ptdef.ptr
          sudo curl -fsSL http://raw.githubusercontent.com/neallober/tbeconfigs/master/PowerTermConfigFolder/ptdef.pts    > $USER_HOME/PowerTermConfigFolder/ptdef.pts
          sudo chown "${USER_UID}" "${USER_HOME}"/PowerTermConfigFolder/ptdef.pts
          sudo curl -fsSL http://raw.githubusercontent.com/neallober/tbeconfigs/master/PowerTermConfigFolder/ptdef.ptx    > $USER_HOME/PowerTermConfigFolder/ptdef.ptx
          sudo chown "${USER_UID}" "${USER_HOME}"/PowerTermConfigFolder/ptdef.ptx
          sudo curl -fsSL http://raw.githubusercontent.com/neallober/tbeconfigs/master/PowerTermConfigFolder/tbe.psl      > $USER_HOME/PowerTermConfigFolder/tbe.psl
          sudo chown "${USER_UID}" "${USER_HOME}"/PowerTermConfigFolder/tbe.psl

    	  fi
    done

    # Download tbe_script.rb and put it in /usr/local/bin
    curl -fsSL http://raw.githubusercontent.com/neallober/tbeconfigs/master/PowerTermConfigFolder/tbe_script.rb > /usr/local/bin/tbe_script.rb
    sudo chmod 755 /usr/local/bin/tbe_script.rb

    # Check for the scan log file
    if [ -e /var/log/tbe_script.log ]; then
      echo "[ ] /var/log/tbe_script.log exists."
    else
      sudo touch /var/log/tbe_script.log
      sudo chmod 777 /var/log/tbe_script.log
      echo "[ ] Created /var/log/tbe_script.log and set permissions to 777"
    fi

    if [ -e $HOME/.ssh/id_rsa.pub ]; then
      echo "[ ] User has already created a public key. Assuming it has already been exchanged."
    else
      echo "[ ] Creating a public key..."
      # Create a public key for this user
      ssh-keygen -t rsa
      echo "[ ] Exchanging public key with server..."
      # Exchange the key with the server
      ssh-copy-id -i $HOME/.ssh/id_rsa.pub scanuser@10.0.1.100
    fi

    echo "[ ] PowerTerm configuration complete."
  fi
else
  echo "[!] Skipping TBE4 & PowerTerm setup."
fi


echo "__________________________________________________"
echo "patch.sh - Script completed."
