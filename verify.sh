#!/bin/bash
set -euo pipefail

TIMEZONE="${TIMEZONE:-GMT}"
ZONEINFO_DIR="/var/db/timezone/zoneinfo"
EXPECTED_LOCALTIME="$ZONEINFO_DIR/$TIMEZONE"

if [ ! -f "$EXPECTED_LOCALTIME" ]; then
	echo "Invalid timezone: $TIMEZONE" >&2
	echo "Use systemsetup -listtimezones to list valid timezone names." >&2
	exit 1
fi

ACTUAL_LOCALTIME="$(readlink /etc/localtime 2>/dev/null || true)"
if [ "$ACTUAL_LOCALTIME" != "$EXPECTED_LOCALTIME" ]; then
	echo "Timezone mismatch" >&2
	echo "Expected /etc/localtime -> $EXPECTED_LOCALTIME" >&2
	echo "Actual   /etc/localtime -> ${ACTUAL_LOCALTIME:-not a symlink}" >&2
	exit 1
fi

echo "Timezone OK: $TIMEZONE"
