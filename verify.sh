#!/bin/bash

set -u

failures=0

check() {
	local description="$1"
	local expected="$2"
	local actual="$3"

	if [ "$actual" = "$expected" ]; then
		echo "PASS: $description"
	else
		echo "FAIL: $description"
		echo "      expected: $expected"
		echo "      actual:   ${actual:-<empty>}"
		failures=$((failures + 1))
	fi
}

softwareupdate_schedule="$(softwareupdate --schedule 2>&1 || true)"
case "$softwareupdate_schedule" in
	*"Automatic check is off"*|*"Automatic checking is off"*|*"off"*)
		echo "PASS: softwareupdate scheduled checks are off"
		;;
	*)
		echo "FAIL: softwareupdate scheduled checks are off"
		echo "      actual:   ${softwareupdate_schedule:-<empty>}"
		failures=$((failures + 1))
		;;
esac

check_default() {
	local description="$1"
	local key="$2"
	local expected="$3"
	local actual

	actual="$(defaults read com.apple.SoftwareUpdate "$key" 2>/dev/null || true)"
	check "$description" "$expected" "$actual"
}

check_default "Automatic software update checks are disabled for current user" "AutomaticCheckEnabled" "0"
check_default "Automatic software update downloads are disabled for current user" "AutomaticDownload" "0"
check_default "Critical update installs are disabled for current user" "CriticalUpdateInstall" "0"
check_default "Major OS notification date is postponed for current user" "MajorOSUserNotificationDate" "2030-01-01 00:00:00 +0000"
check_default "Software update notification date is postponed for current user" "UserNotificationDate" "2030-01-01 00:00:00 +0000"

if launchctl print-disabled system 2>/dev/null | grep -q '"com.apple.MobileAsset.MacSoftwareUpdate" => true'; then
	echo "INFO: com.apple.MobileAsset.MacSoftwareUpdate is disabled in launchctl."
else
	echo "INFO: com.apple.MobileAsset.MacSoftwareUpdate is not disabled in launchctl."
	echo "      This script relies on SoftwareUpdate preferences; disable MobileAsset only after Tahoe VM testing confirms it is needed and safe."
fi

if [ "$failures" -gt 0 ]; then
	echo
	echo "Verification failed. Re-run kiosk setup as the kiosk user, then reboot and run this script again to confirm the settings hold."
	exit 1
fi

echo "Verification passed."
