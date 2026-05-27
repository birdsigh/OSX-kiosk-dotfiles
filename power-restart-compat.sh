#!/bin/bash

# Shared hardware classification for automatic startup after a power cut.

kiosk_model_identifier() {
	local model_identifier

	if [ -n "${KIOSK_TEST_MODEL_IDENTIFIER:-}" ]; then
		printf '%s\n' "$KIOSK_TEST_MODEL_IDENTIFIER"
		return
	fi

	model_identifier="$(/usr/sbin/sysctl -n hw.model 2>/dev/null)"
	if [ -n "$model_identifier" ]; then
		printf '%s\n' "$model_identifier"
		return
	fi

	/usr/sbin/system_profiler SPHardwareDataType 2>/dev/null | /usr/bin/awk -F': ' '/Model Identifier/ { print $2; exit }'
}

kiosk_processor_name() {
	if [ -n "${KIOSK_TEST_PROCESSOR_NAME:-}" ]; then
		printf '%s\n' "$KIOSK_TEST_PROCESSOR_NAME"
		return
	fi

	/usr/sbin/system_profiler SPHardwareDataType 2>/dev/null | /usr/bin/awk -F': ' '/Chip|Processor Name/ { print $2; exit }'
}

kiosk_macos_version() {
	if [ -n "${KIOSK_TEST_MACOS_VERSION:-}" ]; then
		printf '%s\n' "$KIOSK_TEST_MACOS_VERSION"
		return
	fi

	/usr/bin/sw_vers -productVersion 2>/dev/null
}

kiosk_version_at_least() {
	local version="$1"
	local required_major="$2"
	local required_minor="$3"
	local major minor

	major="${version%%.*}"
	minor="${version#*.}"
	minor="${minor%%.*}"

	[ -n "$major" ] || return 1
	[ -n "$minor" ] || minor=0

	if [ "$major" -gt "$required_major" ] 2>/dev/null; then
		return 0
	fi

	if [ "$major" -eq "$required_major" ] 2>/dev/null && [ "$minor" -ge "$required_minor" ] 2>/dev/null; then
		return 0
	fi

	return 1
}

kiosk_autorestartatconnect_status() {
	local model_identifier="$1"
	local processor_name="$2"
	local macos_version="$3"

	case "$model_identifier" in
		# Mac mini (2024): M4, M4 Pro
		# iMac (2024): M4, two-port and four-port models
		# Mac Studio (2025): M4 Max, M3 Ultra
		Mac16,10|Mac16,11|Mac16,2|Mac16,3|Mac16,9|Mac15,14)
			if kiosk_version_at_least "$macos_version" 26 5; then
				printf 'supported\n'
			else
				printf 'unsupported-os\n'
			fi
			;;
		# Earlier Apple Silicon desktop Macs accept or expose the key on some
		# systems, but are not known to actually power on when AC is restored.
		Macmini9,1|Mac14,3|Mac14,12|iMac21,1|iMac21,2|Mac15,4|Mac15,5|Mac13,1|Mac13,2|Mac14,13|Mac14,14)
			printf 'unsupported-apple-silicon\n'
			;;
		*)
			if printf '%s\n' "$processor_name" | /usr/bin/grep -qi 'Intel'; then
				printf 'legacy-intel\n'
			else
				printf 'unknown\n'
			fi
			;;
	esac
}

kiosk_autorestartatconnect_message() {
	local status="$1"
	local model_identifier="$2"
	local processor_name="$3"
	local macos_version="$4"

	case "$status" in
		supported)
			printf 'autorestartatconnect is supported on this Mac (%s, macOS %s).\n' "$model_identifier" "$macos_version"
			;;
		unsupported-os)
			printf 'autorestartatconnect hardware appears supported (%s), but Apple requires macOS Tahoe 26.5 or later. Current macOS: %s.\n' "$model_identifier" "$macos_version"
			;;
		unsupported-apple-silicon)
			printf 'autorestartatconnect is not supported on this Apple Silicon Mac (%s, %s). It may be accepted by pmset but is not known to power on after AC restore.\n' "$model_identifier" "$processor_name"
			;;
		legacy-intel)
			printf 'autorestartatconnect is not supported on Intel Macs (%s, %s). Use the older pmset autorestart key and physically verify power-cut recovery on this model.\n' "$model_identifier" "$processor_name"
			;;
		*)
			printf 'autorestartatconnect support is unknown for this Mac (%s, %s, macOS %s). Physically verify power-cut recovery before deployment.\n' "$model_identifier" "$processor_name" "$macos_version"
			;;
	esac
}
