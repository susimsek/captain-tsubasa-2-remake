#!/bin/sh
set -eu

app_id="captain-tsubasa-2-remake"
app_name="Captain Tsubasa 2 Remake"
executable_name="captain-tsubasa-2-remake.x86_64"
icon_name="captain-tsubasa-2-icon.png"

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
executable="$script_dir/$executable_name"
icon_source="$script_dir/$icon_name"

if [ ! -x "$executable" ]; then
	echo "Game executable not found or not executable: $executable" >&2
	exit 1
fi

if [ ! -f "$icon_source" ]; then
	echo "Application icon not found: $icon_source" >&2
	exit 1
fi

if [ -n "${XDG_DATA_HOME:-}" ]; then
	data_home=$XDG_DATA_HOME
elif [ -n "${HOME:-}" ]; then
	data_home=$HOME/.local/share
else
	echo "Set HOME or XDG_DATA_HOME to install the application launcher." >&2
	exit 1
fi

case "$data_home" in
	/*) ;;
	*) echo "XDG data directory must be an absolute path: $data_home" >&2; exit 1 ;;
esac

newline='
'
case "$executable" in
*"$newline"*) echo "The extracted folder path cannot contain a newline." >&2; exit 1 ;;
esac

escape_exec_argument() {
	printf '%s' "$1" | sed \
		-e 's/\\/\\\\/g' \
		-e 's/"/\\"/g' \
		-e 's/`/\\`/g' \
		-e 's/[$]/\\$/g' \
		-e 's/%/%%/g'
}

escape_desktop_string() {
	printf '%s' "$1" | sed -e 's/\\/\\\\/g'
}

applications_dir="$data_home/applications"
desktop_file="$applications_dir/$app_id.desktop"
desktop_tmp="$desktop_file.tmp.$$"
escaped_executable=$(escape_exec_argument "$executable")
escaped_icon=$(escape_desktop_string "$icon_source")

cleanup() {
	rm -f "$desktop_tmp"
}
trap cleanup EXIT HUP INT TERM

mkdir -p "$applications_dir"

{
	printf '[Desktop Entry]\n'
	printf 'Type=Application\n'
	printf 'Name=%s\n' "$app_name"
	printf 'Comment=Recreation of the original opening and title screen.\n'
	printf 'Exec="%s"\n' "$escaped_executable"
	printf 'Icon=%s\n' "$escaped_icon"
	printf 'Terminal=false\n'
	printf 'Categories=Game;SportsGame;\n'
} > "$desktop_tmp"
chmod 644 "$desktop_tmp"
mv -f "$desktop_tmp" "$desktop_file"

echo "Added $app_name to this user's applications menu."
echo "The launcher points to: $executable"
