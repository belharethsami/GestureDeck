#!/bin/zsh

set -euo pipefail

project_dir="${0:A:h:h}"
dist_dir="$project_dir/dist"
app_bundle="$dist_dir/GestureDeck.app"
dmg_path="$dist_dir/GestureDeck-0.2.0.dmg"

"$project_dir/scripts/build-app.sh" >/dev/null

stage_dir=$(mktemp -d /tmp/gesturedeck-dmg.XXXXXX)
trap 'rm -rf "$stage_dir"' EXIT

ditto "$app_bundle" "$stage_dir/GestureDeck.app"
ln -s /Applications "$stage_dir/Applications"

rm -f "$dmg_path"
hdiutil create \
    -volname "GestureDeck" \
    -srcfolder "$stage_dir" \
    -ov \
    -format UDZO \
    "$dmg_path" >/dev/null

print "$dmg_path"
