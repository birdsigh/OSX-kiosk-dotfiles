#!/bin/bash

failures=0

check_defaults_value() {
	local description="$1"
	local domain="$2"
	local key="$3"
	local expected="$4"
	local actual

	actual="$(defaults read "$domain" "$key" 2>/dev/null)"
	if [[ "$actual" == "$expected" ]]; then
		printf 'PASS: %s\n' "$description"
	else
		printf 'FAIL: %s (expected %s, got %s)\n' "$description" "$expected" "${actual:-<unset>}"
		failures=$((failures + 1))
	fi
}

check_setup_item() {
	local item="$1"

	if /usr/bin/osascript -l JavaScript 2>/dev/null <<EOS | grep -qx "true"
$.NSUserDefaults.alloc.initWithSuiteName('com.apple.SetupAssistant.managed')\
.objectForKey('SkipSetupItems').containsObject('$item')
EOS
	then
		printf 'PASS: Setup Assistant skips %s\n' "$item"
	else
		printf 'FAIL: Setup Assistant skips %s\n' "$item"
		failures=$((failures + 1))
	fi
}

check_defaults_value "Siri assistant disabled" "com.apple.assistant.support" "Assistant Enabled" "0"
check_defaults_value "Siri data sharing declined" "com.apple.assistant.support" "Siri Data Sharing Opt-In Status" "2"
check_defaults_value "Siri status menu hidden" "com.apple.Siri" "StatusMenuVisible" "0"
check_defaults_value "Siri stashed status menu hidden" "com.apple.Siri" "SiriPrefStashedStatusMenuVisible" "0"
check_defaults_value "Siri setup declined" "com.apple.Siri" "UserHasDeclinedEnable" "1"
check_defaults_value "Siri voice trigger disabled" "com.apple.Siri" "VoiceTriggerUserEnabled" "0"
check_defaults_value "Siri setup screen seen" "com.apple.SetupAssistant" "DidSeeSiriSetup" "1"
check_setup_item "Siri"

check_defaults_value "Apple Intelligence feature opt-in disabled" "com.apple.CloudSubscriptionFeatures.optIn" "545129924" "0"
check_defaults_value "Apple Intelligence automatic opt-in disabled" "com.apple.CloudSubscriptionFeatures.optIn" "auto_opt_in" "0"
check_defaults_value "Apple Intelligence device opt-in disabled" "com.apple.CloudSubscriptionFeatures.optIn" "device" "0"
check_defaults_value "Apple Intelligence buddy opt-in disabled" "com.apple.CloudSubscriptionFeatures.optIn" "opted_in_buddy" "0"
check_defaults_value "Apple Intelligence buddy opt-out recorded" "com.apple.CloudSubscriptionFeatures.optIn" "opted_out_buddy" "1"
check_defaults_value "Apple Intelligence setup screen seen" "com.apple.SetupAssistant" "DidSeeIntelligence" "1"
check_setup_item "Intelligence"

if [[ "$failures" -eq 0 ]]; then
	printf 'All checks passed.\n'
else
	printf '%d checks failed.\n' "$failures"
fi

exit "$failures"
