#!/bin/bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/power-restart-compat.sh"

model_identifier="$(kiosk_model_identifier)"
processor_name="$(kiosk_processor_name)"
macos_version="$(kiosk_macos_version)"
restart_status="$(kiosk_autorestartatconnect_status "$model_identifier" "$processor_name" "$macos_version")"
restart_message="$(kiosk_autorestartatconnect_message "$restart_status" "$model_identifier" "$processor_name" "$macos_version")"

pmset_value() {
	local key="$1"

	if [ -n "${KIOSK_TEST_PMSET_G:-}" ]; then
		printf '%s\n' "$KIOSK_TEST_PMSET_G"
	else
		/usr/bin/pmset -g 2>/dev/null
	fi | /usr/bin/awk -v key="$key" '$1 == key { print $2; found=1 } END { if (!found) exit 1 }'
}

case "$restart_status" in
	supported)
		if [ "$(pmset_value autorestartatconnect)" = "1" ]; then
			printf '[PASS] autorestartatconnect is enabled: %s\n' "$restart_message"
		else
			printf '[FAIL] autorestartatconnect is supported but is not enabled: %s\n' "$restart_message"
			exit 1
		fi
		;;
	legacy-intel)
		if [ "$(pmset_value autorestart)" = "1" ]; then
			printf '[INFO] Legacy Intel power restart is enabled with autorestart: %s\n' "$restart_message"
		else
			printf '[INFO] Legacy Intel hardware detected; autorestartatconnect is unsupported and autorestart is not enabled: %s\n' "$restart_message"
		fi
		;;
	unsupported-apple-silicon|unsupported-os)
		printf '[INFO] Unsupported for autorestartatconnect; skipping failure: %s\n' "$restart_message"
		;;
	*)
		printf '[INFO] Unknown autorestartatconnect support; skipping failure: %s\n' "$restart_message"
		;;
esac
