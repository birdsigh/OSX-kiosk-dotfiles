#!/bin/bash

# Disable the crash reporter.
defaults write com.apple.CrashReporter DialogType -string "none"

# Suppress automatic software update checks, downloads, installs, and update notifications.
sudo softwareupdate --schedule off
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false
defaults write com.apple.SoftwareUpdate AutomaticDownload -bool false
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -bool false
defaults write com.apple.SoftwareUpdate MajorOSUserNotificationDate -date "2030-01-01 00:00:00 +0000"
defaults write com.apple.SoftwareUpdate UserNotificationDate -date "2030-01-01 00:00:00 +0000"

# Prevent Time Machine from prompting to use new hard drives as backup volume.
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# Disable Spotlight and indexing.
sudo mdutil -a -i off
sudo mdutil -E /

# Enable the debug menu in Disk Utility.
defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true
defaults write com.apple.DiskUtility advanced-image-options -bool true
