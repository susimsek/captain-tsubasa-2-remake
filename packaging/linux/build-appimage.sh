#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
	echo "Usage: $0 <linux-export-directory> <output.AppImage>" >&2
	exit 2
fi

source_dir=$(cd -- "$1" && pwd -P)
output=$2
app_id="captain-tsubasa-2-remake"
executable_name="${app_id}.x86_64"
appimagetool=${APPIMAGETOOL:-appimagetool}

for required_file in "$executable_name" captain-tsubasa-2-icon.png THIRD_PARTY_NOTICES.txt; do
	if [[ ! -f "$source_dir/$required_file" ]]; then
		echo "Required Linux release file not found: $source_dir/$required_file" >&2
		exit 1
	fi
done

if [[ ! -x "$appimagetool" && "$appimagetool" == */* ]]; then
	echo "appimagetool is not executable: $appimagetool" >&2
	exit 1
fi

mkdir -p "$(dirname -- "$output")"
appdir=$(mktemp -d "${TMPDIR:-/tmp}/${app_id}.AppDir.XXXXXX")
trap 'rm -rf "$appdir"' EXIT
mkdir -p "$appdir/usr/bin"

cp "$source_dir/$executable_name" "$appdir/usr/bin/$executable_name"
cp "$source_dir/THIRD_PARTY_NOTICES.txt" "$appdir/THIRD_PARTY_NOTICES.txt"
cp "$source_dir/captain-tsubasa-2-icon.png" "$appdir/${app_id}.png"
chmod +x "$appdir/usr/bin/$executable_name"

cat > "$appdir/${app_id}.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Captain Tsubasa 2 Remake
Comment=Recreation of the original opening and title screen.
Exec=captain-tsubasa-2-remake.x86_64
Icon=captain-tsubasa-2-remake
Terminal=false
Categories=Game;SportsGame;
DESKTOP

cat > "$appdir/AppRun" <<'APPRUN'
#!/bin/sh
HERE=$(dirname "$(readlink -f "$0")")
exec "$HERE/usr/bin/captain-tsubasa-2-remake.x86_64" "$@"
APPRUN
chmod +x "$appdir/AppRun"

ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 "$appimagetool" \
	--no-appstream "$appdir" "$output"
chmod +x "$output"
echo "Built $output"
