#!/bin/bash

# Keep these checks in lockstep with kiosk.sh. If a macOS update breaks a
# previously passing check, open an issue instead of silently removing it.

set -u

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
	local value

	if ! command -v pmset >/dev/null 2>&1; then
		fail "$description" "pmset is unavailable."
		return
	fi

	value="$(pmset -g 2>/dev/null | awk '$1 == "autorestartatconnect" { print $2; exit }')"

	case "$value" in
		1)
			pass "$description"
			;;
		"")
			info "$description" "autorestartatconnect is not reported by this hardware."
			;;
		*)
			fail "$description" "expected 'autorestartatconnect' to be '1', got '$value'"
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
