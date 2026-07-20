#!/bin/bash

set -euo pipefail

usage() {
	cat <<'EOF'
Usage:
  ./kiosk.sh --check-screen-time-cli
  ./kiosk.sh --create-user USERNAME
  ./kiosk.sh --apply-current-user

Options:
  --check-screen-time-cli  Report macOS version and whether a Screen Time CLI exists.
  --create-user USERNAME   Create a standard local visitor account.
  --apply-current-user     Apply local kiosk defaults to the current user and system.
  -h, --help               Show this help.

Screen Time restrictions are not configured here. On Tahoe, configure them in
System Settings > Screen Time, or deploy restrictions with MDM payloads.
EOF
}

require_macos() {
	if ! command -v sw_vers >/dev/null 2>&1; then
		echo "This script is intended for macOS." >&2
		exit 1
	fi
}

check_screen_time_cli() {
	require_macos
	echo "macOS:"
	sw_vers
	echo

	local found=0
	for dir in /usr/bin /bin /usr/sbin /sbin; do
		for name in screentime ScreenTime familycontrols parentalcontrols; do
			if [ -x "$dir/$name" ]; then
				echo "Found possible Screen Time CLI: $dir/$name"
				found=1
			fi
		done
	done

	if [ "$found" -eq 0 ]; then
		echo "No supported Screen Time CLI found in standard system paths."
	fi
}

create_user() {
	require_macos
	local username="${1:-}"

	if [ -z "$username" ]; then
		echo "--create-user requires a username." >&2
		exit 1
	fi

	if id "$username" >/dev/null 2>&1; then
		echo "User '$username' already exists."
		return
	fi

	read -r -p "Full name [Kiosk Visitor]: " full_name
	full_name="${full_name:-Kiosk Visitor}"

	read -r -s -p "Password for $username: " password
	echo
	read -r -s -p "Confirm password: " password_confirm
	echo

	if [ "$password" != "$password_confirm" ]; then
		echo "Passwords do not match." >&2
		exit 1
	fi

	sudo sysadminctl -addUser "$username" -fullName "$full_name" -password "$password" -home "/Users/$username"
	echo "Created standard local user '$username'."
}

apply_current_user() {
	require_macos

	echo "Applying current-user kiosk defaults for $(id -un)..."

	# Keep the visitor account focused on the kiosk app rather than Finder/Dock.
	defaults write com.apple.dock persistent-apps -array
	defaults write com.apple.dock persistent-others -array
	defaults write com.apple.dock autohide -bool true
	defaults write com.apple.dock autohide-delay -float 0
	defaults write com.apple.dock autohide-time-modifier -float 0
	defaults write com.apple.dock launchanim -bool false
	defaults write com.apple.dock show-process-indicators -bool true

	defaults write com.apple.finder DisableAllAnimations -bool true
	defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
	defaults write com.apple.finder QuitMenuItem -bool false
	defaults write NSGlobalDomain AppleShowAllExtensions -bool true
	defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
	defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true
	defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

	defaults write com.apple.Safari AutoOpenSafeDownloads -bool false
	defaults write com.apple.Safari HomePage -string "about:blank"
	defaults write com.apple.screencapture disable-shadow -bool true
	defaults write com.apple.screencapture type -string "png"
	defaults -currentHost write com.apple.screensaver idleTime 0

	sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName
	sudo pmset sleep 0
	sudo pmset displaysleep 0
	sudo pmset disksleep 0
	sudo pmset repeat restart MTWRFSU 02:00:00
	sudo mdutil -a -i off || true

	for app in Dock Finder Safari SystemUIServer; do
		killall "$app" >/dev/null 2>&1 || true
	done

	echo "Done. Configure Screen Time manually in System Settings or via MDM."
}

if [ "$#" -eq 0 ]; then
	usage
	exit 0
fi

case "$1" in
	--check-screen-time-cli)
		check_screen_time_cli
		;;
	--create-user)
		create_user "${2:-}"
		;;
	--apply-current-user)
		apply_current_user
		;;
	-h|--help)
		usage
		;;
	*)
		echo "Unknown option: $1" >&2
		usage >&2
		exit 1
		;;
esac
