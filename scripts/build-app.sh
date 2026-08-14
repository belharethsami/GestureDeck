#!/bin/zsh

set -euo pipefail

project_dir="${0:A:h:h}"
configuration="${CONFIGURATION:-release}"
dist_dir="$project_dir/dist"
app_bundle="$dist_dir/GestureDeck.app"
contents_dir="$app_bundle/Contents"
resources_dir="$contents_dir/Resources"
frameworks_dir="$contents_dir/Frameworks"
macos_dir="$contents_dir/MacOS"
arm_scratch="$project_dir/.build-arm64"
x86_scratch="$project_dir/.build-x86_64"

build_architecture() {
    local architecture="$1"
    local scratch="$2"

    swift build \
        --package-path "$project_dir" \
        --scratch-path "$scratch" \
        -c "$configuration" \
        --product GestureDeck \
        --triple "$architecture-apple-macosx15.0"

    swift build \
        --package-path "$project_dir" \
        --scratch-path "$scratch" \
        -c "$configuration" \
        --product GestureDeck \
        --triple "$architecture-apple-macosx15.0" \
        --show-bin-path
}

arm_bin_dir=$(build_architecture arm64 "$arm_scratch" | tail -1)
x86_bin_dir=$(build_architecture x86_64 "$x86_scratch" | tail -1)

if [[ "$app_bundle" != "$project_dir/dist/GestureDeck.app" ]]; then
    print -u2 "Refusing to replace an unexpected app path: $app_bundle"
    exit 1
fi

rm -rf "$app_bundle"
mkdir -p "$macos_dir" "$resources_dir" "$frameworks_dir"

lipo -create \
    "$arm_bin_dir/GestureDeck" \
    "$x86_bin_dir/GestureDeck" \
    -output "$macos_dir/GestureDeck"

install_name_tool \
    -add_rpath @executable_path/../Frameworks \
    "$macos_dir/GestureDeck"

ditto \
    "$arm_bin_dir/OpenMultitouchSupportXCF.framework" \
    "$frameworks_dir/OpenMultitouchSupportXCF.framework"

cp "$project_dir/Resources/Info.plist" "$contents_dir/Info.plist"
cp "$project_dir/THIRD_PARTY_NOTICES.md" "$resources_dir/THIRD_PARTY_NOTICES.md"

icon_work=$(mktemp -d /tmp/gesturedeck-icon.XXXXXX)
trap 'rm -rf "$icon_work"' EXIT

xcrun swift "$project_dir/scripts/generate-icon.swift" "$icon_work/icon_1024x1024.png"
mkdir -p "$icon_work/GestureDeck.iconset"

for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$icon_work/icon_1024x1024.png" \
        --out "$icon_work/GestureDeck.iconset/icon_${size}x${size}.png" >/dev/null
    retina_size=$((size * 2))
    sips -z "$retina_size" "$retina_size" "$icon_work/icon_1024x1024.png" \
        --out "$icon_work/GestureDeck.iconset/icon_${size}x${size}@2x.png" >/dev/null
done

iconutil -c icns "$icon_work/GestureDeck.iconset" -o "$resources_dir/GestureDeck.icns"

if xcrun --find swift-stdlib-tool >/dev/null 2>&1; then
    xcrun swift-stdlib-tool \
        --copy \
        --platform macosx \
        --scan-executable "$macos_dir/GestureDeck" \
        --scan-folder "$frameworks_dir" \
        --destination "$frameworks_dir"
fi

find "$frameworks_dir" -type f \( -name '*.dylib' -o -perm -111 \) -exec codesign --force --sign - {} \;
codesign --force --deep --sign - "$app_bundle"

print "$app_bundle"
