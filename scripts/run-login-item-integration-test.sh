#!/bin/zsh

set -euo pipefail

app_bundle="/Applications/GestureDeck.app"
executable="$app_bundle/Contents/MacOS/GestureDeck"
report_file=$(mktemp /tmp/gesturedeck-login-item-report.XXXXXX)
raw_report_file=$(mktemp /tmp/gesturedeck-login-item-raw.XXXXXX)
error_file=$(mktemp /tmp/gesturedeck-login-item-error.XXXXXX)
enabled_by_test=false

if [[ "$app_bundle" != "/Applications/GestureDeck.app" ]]; then
    print -u2 "Refusing to use an unexpected app path: $app_bundle"
    exit 1
fi

if [[ ! -x "$executable" ]]; then
    print -u2 "Install GestureDeck 0.2.0 in Applications before running this test."
    exit 1
fi

installed_version=$(/usr/libexec/PlistBuddy \
    -c 'Print :CFBundleShortVersionString' \
    "$app_bundle/Contents/Info.plist")
if [[ "$installed_version" != "0.2.0" ]]; then
    print -u2 "Expected GestureDeck 0.2.0 in Applications, found $installed_version."
    exit 1
fi

run_diagnostic() {
    rm -f "$report_file"
    /usr/bin/open -W -n "$app_bundle" --args \
        --diagnostics 0.4 \
        --diagnostics-output "$report_file" \
        "$@" \
        >"$raw_report_file" 2>"$error_file"

    if [[ ! -s "$report_file" ]]; then
        print -u2 "GestureDeck did not write a diagnostics report."
        /usr/bin/sed -n '1,120p' "$error_file" >&2
        return 1
    fi
}

report_value() {
    /usr/bin/plutil -extract "$1" raw -o - "$report_file"
}

cleanup() {
    if [[ "$enabled_by_test" == true && -x "$executable" ]]; then
        run_diagnostic --set-launch-at-login off >/dev/null 2>&1 || true
    fi
    rm -f "$report_file" "$raw_report_file" "$error_file"
}
trap cleanup EXIT

run_diagnostic
initial_state=$(report_value launchAtLogin)
if [[ "$initial_state" != "disabled" && "$initial_state" != "unavailable" ]]; then
    print -u2 "Login-item state is already $initial_state; refusing to disturb the existing preference."
    exit 1
fi

run_diagnostic --set-launch-at-login on
enabled_by_test=true
enabled_state=$(report_value launchAtLogin)
enabled_error=$(report_value launchAtLoginError 2>/dev/null || print "none")

if [[ "$enabled_state" != "enabled" ]]; then
    print -u2 "Expected enabled login item, got $enabled_state: $enabled_error"
    exit 1
fi

run_diagnostic --set-launch-at-login off
disabled_state=$(report_value launchAtLogin)
disabled_error=$(report_value launchAtLoginError 2>/dev/null || print "none")
enabled_by_test=false

if [[ "$disabled_state" != "disabled" ]]; then
    print -u2 "Expected disabled login item, got $disabled_state: $disabled_error"
    exit 1
fi

print "Login-item integration test passed: disabled → enabled → disabled."
