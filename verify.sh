#!/bin/bash

set -euo pipefail

failures=0

check_equal() {
	local description="$1"
	local expected="$2"
	shift 2

	local actual
	if ! actual="$("$@" 2>/dev/null)"; then
		printf 'FAIL: %s (command failed: %s)\n' "$description" "$*"
		failures=$((failures + 1))
		return
	fi

	if [[ "$actual" == "$expected" ]]; then
		printf 'PASS: %s\n' "$description"
	else
		printf 'FAIL: %s (expected %q, got %q)\n' "$description" "$expected" "$actual"
		failures=$((failures + 1))
	fi
}

product_version="$(sw_vers -productVersion)"

check_equal "Apple Account name display order set" "1" \
	defaults read NSGlobalDomain NSPersonNameDefaultDisplayNameOrder

check_equal "iCloud setup marked as seen" "1" \
	defaults read com.apple.SetupAssistant DidSeeCloudSetup

check_equal "Setup Assistant gesture movie suppressed" "none" \
	defaults read com.apple.SetupAssistant GestureMovieSeen

check_equal "Setup Assistant cloud product version is current" "$product_version" \
	defaults read com.apple.SetupAssistant LastSeenCloudProductVersion

if (( failures > 0 )); then
	printf '\n%d verification check(s) failed.\n' "$failures"
	exit 1
fi

printf '\nAll verification checks passed.\n'
