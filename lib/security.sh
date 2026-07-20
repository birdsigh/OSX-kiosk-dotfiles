#!/bin/bash

# Save to disk, not to iCloud, by default.
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Mark Apple Account/iCloud onboarding as already seen so kiosk setup is not interrupted.
defaults write NSGlobalDomain NSPersonNameDefaultDisplayNameOrder -int 1
defaults write com.apple.SetupAssistant DidSeeCloudSetup -bool true
defaults write com.apple.SetupAssistant GestureMovieSeen -string "none"
defaults write com.apple.SetupAssistant LastSeenCloudProductVersion -string "$(sw_vers -productVersion)"

# Disable the "Are you sure you want to open this application?" dialog.
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Disable Gatekeeper assessments so unsigned creative coding apps can launch.
# On recent macOS releases this may still require Privacy & Security approval or MDM.
sudo spctl --master-disable || sudo spctl --global-disable || true
gatekeeper_status="$(spctl --status 2>/dev/null || true)"
if [ "$gatekeeper_status" != "assessments disabled" ]; then
	echo "Warning: Gatekeeper is not disabled; spctl --status reports: ${gatekeeper_status:-unknown}"
	echo "Unsigned apps may still need Privacy & Security approval or quarantine removal."
fi
unset gatekeeper_status
