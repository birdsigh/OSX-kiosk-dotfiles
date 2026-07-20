#!/bin/bash

# Keep these checks in lockstep with kiosk.sh. If a macOS update breaks a
# previously passing check, open an issue instead of silently removing it.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/power-restart-compat.sh"

PASS_COUNT=0
FAIL_COUNT=0
INFO_COUNT=0

pass() {
	echo "[PASS] $1"
	PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
	echo "[FAIL] $1"
	if [ "${2:-}" != "" ]; then
		echo "       ${2}"
	fi
	FAIL_COUNT=$((FAIL_COUNT + 1))
}

info() {
	echo "[INFO] $1"
	if [ "${2:-}" != "" ]; then
		echo "       ${2}"
	fi
	INFO_COUNT=$((INFO_COUNT + 1))
}

read_defaults() {
	if [ "${1:-}" = "-currentHost" ]; then
		shift
		defaults -currentHost read "$@" 2>/dev/null
	else
		defaults read "$@" 2>/dev/null
	fi
}

check_equals() {
	local description="$1"
	local expected="$2"
	shift 2

	local actual
	actual="$(read_defaults "$@")"

	if [ "$actual" = "$expected" ]; then
		pass "$description"
	else
		fail "$description" "expected '$expected', got '${actual:-<unset>}'"
	fi
}

check_bool() {
	local description="$1"
	local expected="$2"
	shift 2

	local actual
	actual="$(read_defaults "$@")"

	case "$expected:$actual" in
		1:1|1:true|1:YES|1:yes|0:0|0:false|0:NO|0:no)
			pass "$description"
			;;
		*)
			fail "$description" "expected '$expected', got '${actual:-<unset>}'"
			;;
	esac
}

check_major_version_at_least() {
	local description="$1"
	local minimum_major="$2"
	local version
	local major

	if ! command -v sw_vers >/dev/null 2>&1; then
		fail "$description" "sw_vers is unavailable; this script must run on macOS."
		return
	fi

	version="$(sw_vers -productVersion 2>/dev/null)"
	major="${version%%.*}"

	if [ "$major" -ge "$minimum_major" ] 2>/dev/null; then
		pass "$description"
	else
		fail "$description" "expected major version >= $minimum_major, got '${version:-<unknown>}'"
	fi
}

check_pmset_value() {
	local key="$1"
	local expected="$2"
	local description="$3"
	local value

	if ! command -v pmset >/dev/null 2>&1; then
		fail "$description" "pmset is unavailable."
		return
	fi

	value="$(pmset -g 2>/dev/null | awk -v key="$key" '$1 == key { print $2; exit }')"

	if [ "$value" = "$expected" ]; then
		pass "$description"
	else
		fail "$description" "expected '$key' to be '$expected', got '${value:-<unset>}'"
	fi
}

check_autorestartatconnect() {
	local description="Power management: restart automatically after reconnecting power"
	local model_identifier processor_name macos_version restart_status restart_message value

	model_identifier="$(kiosk_model_identifier)"
	processor_name="$(kiosk_processor_name)"
	macos_version="$(kiosk_macos_version)"
	restart_status="$(kiosk_autorestartatconnect_status "$model_identifier" "$processor_name" "$macos_version")"
	restart_message="$(kiosk_autorestartatconnect_message "$restart_status" "$model_identifier" "$processor_name" "$macos_version")"

	case "$restart_status" in
		supported)
			value="$(pmset -g 2>/dev/null | awk '$1 == "autorestartatconnect" { print $2; exit }')"
			if [ "$value" = "1" ]; then
				pass "$description"
			else
				fail "$description" "$restart_message Expected 'autorestartatconnect' to be '1', got '${value:-<unset>}'."
			fi
			;;
		legacy-intel)
			value="$(pmset -g 2>/dev/null | awk '$1 == "autorestart" { print $2; exit }')"
			info "$description" "$restart_message autorestart=${value:-<unset>}."
			;;
		*)
			info "$description" "$restart_message"
			;;
	esac
}

check_restart_schedule() {
	local description="Power management: daily restart schedule is present"
	local schedule

	if ! command -v pmset >/dev/null 2>&1; then
		fail "$description" "pmset is unavailable."
		return
	fi

	schedule="$(pmset -g sched 2>/dev/null)"

	if printf '%s\n' "$schedule" | grep -qi 'restart'; then
		pass "$description"
	else
		fail "$description" "no restart event found in pmset schedule."
	fi
}

check_spotlight_disabled() {
	local description="Spotlight: indexing is disabled on /"
	local status

	if ! command -v mdutil >/dev/null 2>&1; then
		fail "$description" "mdutil is unavailable."
		return
	fi

	status="$(mdutil -s / 2>/dev/null)"

	if printf '%s\n' "$status" | grep -Eqi '(Indexing|Spotlight server) is disabled'; then
		pass "$description"
	else
		fail "$description" "expected indexing to be disabled, got '${status:-<no output>}'"
	fi
}

check_screen_sharing_enabled() {
	local description="Sharing: screen sharing launch daemon is enabled"
	local status

	if ! command -v launchctl >/dev/null 2>&1; then
		fail "$description" "launchctl is unavailable."
		return
	fi

	status="$(launchctl print-disabled system 2>/dev/null | awk -F'=> ' '/com\.apple\.screensharing/ { gsub(/[[:space:]]/, "", $2); print $2; exit }')"

	if [ "$status" = "false" ] || [ "$status" = "enabled" ]; then
		pass "$description"
	else
		fail "$description" "expected com.apple.screensharing disabled state to be false, got '${status:-<unset>}'"
	fi
}

check_general_ui_ux() {
	check_bool "General UI/UX: window animations are disabled" "0" NSGlobalDomain NSAutomaticWindowAnimationsEnabled
	check_bool "General UI/UX: Resume is disabled system-wide" "0" NSGlobalDomain NSQuitAlwaysKeepsWindows
	check_bool "General UI/UX: automatic termination is disabled" "1" NSGlobalDomain NSDisableAutomaticTermination
	check_equals "General UI/UX: crash reporter dialog is disabled" "none" com.apple.CrashReporter DialogType
	check_bool "General UI/UX: new documents save to disk by default" "0" NSGlobalDomain NSDocumentSaveNewDocumentsToCloud
	check_bool "General UI/UX: Launch Services quarantine dialog is disabled" "0" com.apple.LaunchServices LSQuarantine
}

check_apple_account_onboarding() {
	check_equals "Apple Account: name display order is set" "1" NSGlobalDomain NSPersonNameDefaultDisplayNameOrder
	check_bool "Apple Account: iCloud setup is marked as seen" "1" com.apple.SetupAssistant DidSeeCloudSetup
	check_equals "Apple Account: Setup Assistant gesture movie is suppressed" "none" com.apple.SetupAssistant GestureMovieSeen
	check_equals "Apple Account: cloud product version is current" "$(sw_vers -productVersion 2>/dev/null)" com.apple.SetupAssistant LastSeenCloudProductVersion
}

check_siri_and_intelligence() {
	check_bool "Siri: assistant is disabled" "0" com.apple.assistant.support "Assistant Enabled"
	check_equals "Siri: data sharing is declined" "2" com.apple.assistant.support "Siri Data Sharing Opt-In Status"
	check_bool "Siri: setup is marked as seen" "1" com.apple.SetupAssistant DidSeeSiriSetup
	check_bool "Apple Intelligence: feature opt-in is disabled" "0" com.apple.CloudSubscriptionFeatures.optIn 545129924
	check_bool "Apple Intelligence: automatic opt-in is disabled" "0" com.apple.CloudSubscriptionFeatures.optIn auto_opt_in
	check_bool "Apple Intelligence: setup is marked as seen" "1" com.apple.SetupAssistant DidSeeIntelligence
}

check_power_management() {
	check_pmset_value "sleep" "0" "Power management: system sleep is disabled"
	check_autorestartatconnect
	check_restart_schedule
}

check_input() {
	check_bool "Input: press-and-hold is disabled" "0" NSGlobalDomain ApplePressAndHoldEnabled
	check_bool "Input: automatic spelling correction is disabled" "0" NSGlobalDomain NSAutomaticSpellingCorrectionEnabled
}

check_screen() {
	check_equals "Screen: screensaver idle time is disabled" "0" -currentHost com.apple.screensaver idleTime
}

check_finder() {
	check_bool "Finder: animations are disabled" "1" com.apple.finder DisableAllAnimations
	check_bool "Finder: hidden files are shown" "1" com.apple.finder AppleShowAllFiles
	check_bool "Finder: extension change warning is disabled" "0" com.apple.finder FXEnableExtensionChangeWarning
	check_bool "Finder: network .DS_Store creation is disabled" "1" com.apple.desktopservices DSDontWriteNetworkStores
}

check_dock() {
	check_bool "Dock: autohide is enabled" "1" com.apple.dock autohide
	check_bool "Dock: launch animation is disabled" "0" com.apple.dock launchanim
}

check_time_machine() {
	check_bool "Time Machine: new disk backup prompts are disabled" "1" com.apple.TimeMachine DoNotOfferNewDisksForBackup
}

check_general_ui_ux
check_apple_account_onboarding
check_siri_and_intelligence
check_power_management
check_input
check_screen
check_finder
check_dock
check_time_machine
check_spotlight_disabled
check_screen_sharing_enabled
check_major_version_at_least "macOS version: major version is at least 26" 26

echo
echo "Results: ${PASS_COUNT} passed, ${FAIL_COUNT} failed, ${INFO_COUNT} info"

if [ "$FAIL_COUNT" -gt 0 ]; then
	exit 1
fi

exit 0
