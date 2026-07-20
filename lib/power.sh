#!/bin/bash

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$LIB_DIR/../power-restart-compat.sh"

# Never go into computer sleep mode.
sudo pmset sleep 0

# Restart automatically from power failure where supported. On older Intel Macs,
# use the older autorestart setting; on unsupported Apple Silicon, warn instead
# of claiming a setting will reliably power the Mac back on.
power_model_identifier="$(kiosk_model_identifier)"
power_processor_name="$(kiosk_processor_name)"
power_macos_version="$(kiosk_macos_version)"
power_restart_status="$(kiosk_autorestartatconnect_status "$power_model_identifier" "$power_processor_name" "$power_macos_version")"

case "$power_restart_status" in
	supported)
		sudo pmset autorestartatconnect 1
		;;
	legacy-intel)
		printf '[WARN] %s\n' "$(kiosk_autorestartatconnect_message "$power_restart_status" "$power_model_identifier" "$power_processor_name" "$power_macos_version")" >&2
		sudo pmset autorestart 1
		;;
	*)
		printf '[WARN] %s\n' "$(kiosk_autorestartatconnect_message "$power_restart_status" "$power_model_identifier" "$power_processor_name" "$power_macos_version")" >&2
		;;
esac

# Restart at 2am every day.
# Note: two separate pmset repeat calls conflict; only the last one takes effect.
# Using a single 'restart' event is cleaner and works on Apple Silicon.
sudo pmset repeat restart MTWRFSU 02:00:00
