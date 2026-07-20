#!/bin/bash

# Suppress notification banners and alerts for kiosk operation on macOS Tahoe.
notification_center_label="com.apple.notificationcenterui.agent"
notification_center_plist="/System/Library/LaunchAgents/com.apple.notificationcenterui.plist"
launchctl disable "gui/$(id -u)/${notification_center_label}" 2>/dev/null || true
launchctl bootout "gui/$(id -u)" "${notification_center_plist}" 2>/dev/null || true
unset notification_center_label notification_center_plist

# Disable Siri and suppress Siri setup prompts.
defaults write com.apple.assistant.support "Assistant Enabled" -bool false
defaults write com.apple.assistant.support "Siri Data Sharing Opt-In Status" -int 2
defaults write com.apple.Siri StatusMenuVisible -bool false
defaults write com.apple.Siri SiriPrefStashedStatusMenuVisible -bool false
defaults write com.apple.Siri UserHasDeclinedEnable -bool true
defaults write com.apple.Siri VoiceTriggerUserEnabled -bool false
defaults write com.apple.SetupAssistant DidSeeSiriSetup -bool true
defaults write com.apple.SetupAssistant.managed SkipSetupItems -array-add "Siri"

# Disable Apple Intelligence and suppress its first-run onboarding on Tahoe.
defaults write com.apple.CloudSubscriptionFeatures.optIn "545129924" -bool false
defaults write com.apple.CloudSubscriptionFeatures.optIn "auto_opt_in" -bool false
defaults write com.apple.CloudSubscriptionFeatures.optIn "device" -bool false
defaults write com.apple.CloudSubscriptionFeatures.optIn "opted_in_buddy" -bool false
defaults write com.apple.CloudSubscriptionFeatures.optIn "opted_out_buddy" -bool true
defaults write com.apple.SetupAssistant DidSeeIntelligence -bool true
defaults write com.apple.SetupAssistant.managed SkipSetupItems -array-add "Intelligence"
