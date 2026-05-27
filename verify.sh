#!/bin/bash
set -euo pipefail

uid="$(id -u)"
notification_center_label="com.apple.notificationcenterui.agent"

failures=0

check_notification_center_disabled() {
	local disabled_state

	if ! disabled_state="$(launchctl print-disabled "gui/${uid}" 2>/dev/null)"; then
		echo "FAIL notification-center: could not read disabled launchd state for gui/${uid}"
		failures=$((failures + 1))
		return
	fi

	if ! grep -F "\"${notification_center_label}\" => disabled" <<<"${disabled_state}" >/dev/null; then
		echo "FAIL notification-center: ${notification_center_label} is not persistently disabled"
		failures=$((failures + 1))
		return
	fi

	if launchctl print "gui/${uid}/${notification_center_label}" >/dev/null 2>&1; then
		echo "FAIL notification-center: ${notification_center_label} is still loaded in the current GUI session"
		failures=$((failures + 1))
		return
	fi

	echo "PASS notification-center: ${notification_center_label} is disabled and not loaded"
}

check_notification_center_disabled

if [ "${failures}" -gt 0 ]; then
	exit 1
fi
