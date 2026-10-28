#!/bin/sh
set -eu

app_id="captain-tsubasa-2-remake"

if [ -n "${XDG_DATA_HOME:-}" ]; then
	data_home=$XDG_DATA_HOME
elif [ -n "${HOME:-}" ]; then
	data_home=$HOME/.local/share
else
	echo "Set HOME or XDG_DATA_HOME to remove the application launcher." >&2
	exit 1
fi

case "$data_home" in
	/*) ;;
	*) echo "XDG data directory must be an absolute path: $data_home" >&2; exit 1 ;;
esac

rm -f "$data_home/applications/$app_id.desktop"

echo "Removed $app_id from this user's applications menu."
