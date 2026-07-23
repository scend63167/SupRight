#!/bin/zsh
set -euo pipefail

script_dir=${0:A:h}
project_dir=${script_dir:h}
template_dir="$project_dir/SupRightFinderExtension/Resources/Templates"
if [[ -n "${SOFFICE_BIN:-}" ]]; then
  soffice_bin="$SOFFICE_BIN"
elif (( $+commands[soffice] )); then
  soffice_bin="${commands[soffice]}"
else
  print -u2 "LibreOffice is required. Install it, or set SOFFICE_BIN to its soffice executable."
  exit 1
fi
work_dir=$(mktemp -d)

cleanup() {
  rm -rf "$work_dir"
}
trap cleanup EXIT

mkdir -p "$template_dir" "$work_dir/output"
touch "$work_dir/Blank.txt" "$work_dir/Blank.csv"

"$soffice_bin" --headless --convert-to docx --outdir "$work_dir/output" "$work_dir/Blank.txt"
"$soffice_bin" --headless --convert-to xlsx --outdir "$work_dir/output" "$work_dir/Blank.csv"

mv "$work_dir/output/Blank.docx" "$template_dir/Blank.docx"
mv "$work_dir/output/Blank.xlsx" "$template_dir/Blank.xlsx"

unzip -t "$template_dir/Blank.docx" >/dev/null
unzip -t "$template_dir/Blank.xlsx" >/dev/null

# Blank.pptx is exported from a blank Keynote document because Keynote is the
# canonical local macOS exporter for the PowerPoint format. Keep that source
# template at SupRightFinderExtension/Resources/Templates/Blank.pptx and validate it here.
test -f "$template_dir/Blank.pptx"
unzip -t "$template_dir/Blank.pptx" >/dev/null
