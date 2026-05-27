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

gatekeeper_status="$(spctl --status 2>&1)"
check "Gatekeeper assessments are disabled for unsigned kiosk apps" "assessments disabled" "$gatekeeper_status"

if spctl --disable-status >/dev/null 2>&1; then
	echo "INFO: Gatekeeper Anywhere option is available in Privacy & Security."
else
	echo "INFO: Gatekeeper Anywhere option is not reported as available by spctl --disable-status."
fi

if [ "$failures" -gt 0 ]; then
	echo
	echo "Verification failed. On macOS 15/Tahoe and later, spctl may require System Settings confirmation or a SystemPolicyControl profile before unsigned apps launch without dialogs."
	exit 1
fi

echo "Verification passed."
