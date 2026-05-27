#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")"

# Suppress automatic software update checks, downloads, installs, and update
# notifications before applying the rest of the kiosk setup.
sudo softwareupdate --schedule off
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false
defaults write com.apple.SoftwareUpdate AutomaticDownload -bool false
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -bool false
defaults write com.apple.SoftwareUpdate MajorOSUserNotificationDate -date "2030-01-01 00:00:00 +0000"
defaults write com.apple.SoftwareUpdate UserNotificationDate -date "2030-01-01 00:00:00 +0000"

# Keep kiosk setup discoverable under the script name used by current issue
# tracking while preserving the existing .osx setup entry point.
./.osx
