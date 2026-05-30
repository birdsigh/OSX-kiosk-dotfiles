#!/bin/bash

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

require_macos_tahoe() {
	if ! command -v sw_vers >/dev/null 2>&1; then
		echo "kiosk.sh is intended for macOS." >&2
		exit 1
	fi

	local version major
	version="$(sw_vers -productVersion)"
	major="${version%%.*}"

	if ! [ "$major" -ge 26 ] 2>/dev/null; then
		echo "Warning: target test environment is macOS Tahoe 26.x; current version is ${version}." >&2
	fi
}

# Ask for the administrator password upfront.
sudo -v

# Keep-alive: update existing sudo time stamp until kiosk.sh has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

require_macos_tahoe

source "$ROOT_DIR/lib/power.sh"
source "$ROOT_DIR/lib/ui.sh"
source "$ROOT_DIR/lib/system.sh"
source "$ROOT_DIR/lib/sharing.sh"
source "$ROOT_DIR/lib/security.sh"
source "$ROOT_DIR/lib/notifications.sh"

for app in "Address Book" "Calendar" "Contacts" "Dashboard" "Dock" "Finder" \
	"Mail" "Safari" "SizeUp" "SystemUIServer" "Terminal" "Transmission" \
	"Twitter" "iCal" "iTunes"; do
	killall "$app" > /dev/null 2>&1 || true
done

echo "Done. Note that some of these changes require a logout/restart to take effect."
