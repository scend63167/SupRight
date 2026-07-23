#!/bin/zsh

set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
version="${VERSION:-0.2.0}"
output_dir="$project_root/dist"
archive_path="$output_dir/SupRight-v${version}.xcarchive"
app_path="$archive_path/Products/Applications/SupRight.app"
zip_path="$output_dir/SupRight-v${version}-macos-development-signed.zip"
checksum_path="$zip_path.sha256"
signing_identity="${SIGNING_IDENTITY:-}"

if [[ -z "$signing_identity" ]]; then
  print -u2 "Set SIGNING_IDENTITY to an Apple Development signing identity before packaging."
  exit 1
fi

mkdir -p "$output_dir"
rm -rf "$archive_path"
rm -f "$zip_path" "$checksum_path"

xcodebuild \
  -project "$project_root/SupRight.xcodeproj" \
  -scheme SupRight \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath "$archive_path" \
  CODE_SIGNING_ALLOWED=NO \
  archive

if [[ ! -d "$app_path" ]]; then
  print -u2 "Expected app bundle was not created: $app_path"
  exit 1
fi

extension_path="$app_path/Contents/PlugIns/SupRightFinderExtension.appex"
codesign --force --sign "$signing_identity" \
  --entitlements "$project_root/SupRightFinderExtension/SupRightFinderExtension.entitlements" \
  "$extension_path"
codesign --force --sign "$signing_identity" \
  --entitlements "$project_root/SupRight/SupRight.entitlements" \
  "$app_path"
codesign --verify --deep --strict --verbose=2 "$app_path"

ditto -c -k --norsrc --keepParent "$app_path" "$zip_path"
shasum -a 256 "$zip_path" > "$checksum_path"

print "Created: $zip_path"
print "Checksum: $checksum_path"
