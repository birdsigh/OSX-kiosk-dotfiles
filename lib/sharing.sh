#!/bin/bash

# Bluetooth is left enabled by default. If your kiosk uses no Bluetooth
# peripherals and you want to disable it, uncomment the following:
#defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -bool false
#sudo launchctl disable system/com.apple.blued
#sudo killall blued

# Enable Screen Sharing.
sudo launchctl enable system/com.apple.screensharing
sudo launchctl load -F /System/Library/LaunchDaemons/com.apple.screensharing.plist

# File Sharing is intentionally not enabled by default. Enable it manually if the
# kiosk needs SMB access, then validate the network exposure in the gallery setup.
#sudo launchctl enable system/com.apple.smbd
#sudo launchctl load -F /System/Library/LaunchDaemons/com.apple.smbd.plist
