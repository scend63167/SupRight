#!/bin/zsh

set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
version="${VERSION:-0.1.0}"
output_dir="$project_root/dist"
archive_path="$output_dir/SupRight-v${version}.xcarchive"
app_path="$archive_path/Products/Applications/SupRight.app"
zip_path="$output_dir/SupRight-v${version}-macos-unsigned.zip"
checksum_path="$zip_path.sha256"

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

ditto -c -k --norsrc --keepParent "$app_path" "$zip_path"
shasum -a 256 "$zip_path" > "$checksum_path"

print "Created: $zip_path"
print "Checksum: $checksum_path"
