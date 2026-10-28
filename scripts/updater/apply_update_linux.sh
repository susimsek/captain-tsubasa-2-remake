#!/bin/sh
set -u

archive="$1"
target_executable="$2"
game_pid="$3"
status_file="$4"
appimage_update=0

write_status() {
	printf '%s\n' "$1" > "$status_file"
}

case "${5:-archive}" in
	appimage)
		appimage_update=1
		;;
	archive)
		;;
	*)
		write_status "failed:package"
		exit 1
		;;
esac

relaunch_game() {
	if [ -x "$target_executable" ]; then
		"$target_executable" >/dev/null 2>&1 &
		launch_pid=$!
		/bin/sleep 0.5
		/bin/kill -0 "$launch_pid" 2>/dev/null
		return $?
	fi
	return 1
}

while /bin/kill -0 "$game_pid" 2>/dev/null; do
	/bin/sleep 0.25
done

parent_dir=$(/usr/bin/dirname "$target_executable")
if [ ! -f "$target_executable" ] || [ ! -w "$parent_dir" ]; then
	write_status "failed:folder"
	relaunch_game
	exit 1
fi

stage_dir=$(/usr/bin/mktemp -d "$parent_dir/.captain-tsubasa-update.XXXXXX") || {
	write_status "failed:stage"
	relaunch_game
	exit 1
}
backup_executable="${target_executable}.update-backup.$$"
temporary_executable="${target_executable}.update-new.$$"
restore_needed=0
relaunch_after_cleanup=0

cleanup() {
	if [ "$restore_needed" -eq 1 ] && [ -f "$backup_executable" ]; then
		if ! /bin/cp -f "$backup_executable" "$target_executable" || ! /bin/chmod +x "$target_executable"; then
			write_status "failed:recovery"
		fi
	fi
	/bin/rm -rf "$stage_dir"
	/bin/rm -f "$backup_executable" "$temporary_executable"
	if [ "$relaunch_after_cleanup" -eq 1 ]; then
		relaunch_game
	fi
}
trap cleanup EXIT

if [ "$appimage_update" -eq 1 ]; then
	new_executable="$archive"
	if [ ! -f "$new_executable" ] || [ -L "$new_executable" ]; then
		write_status "failed:package"
		relaunch_after_cleanup=1
		exit 1
	fi
else
	if ! /bin/tar -xzf "$archive" -C "$stage_dir" --no-same-owner --no-same-permissions -- captain-tsubasa-2-remake.x86_64 THIRD_PARTY_NOTICES.txt; then
		write_status "failed:unpack"
		relaunch_after_cleanup=1
		exit 1
	fi

	new_executable="$stage_dir/captain-tsubasa-2-remake.x86_64"
	if [ ! -f "$new_executable" ] || [ -L "$new_executable" ]; then
		write_status "failed:package"
		relaunch_after_cleanup=1
		exit 1
	fi
fi

if ! /bin/cp -f "$target_executable" "$backup_executable"; then
	write_status "failed:backup"
	relaunch_after_cleanup=1
	exit 1
fi
restore_needed=1

if ! /bin/cp -f "$new_executable" "$temporary_executable" || ! /bin/chmod +x "$temporary_executable" || ! /bin/mv -f "$temporary_executable" "$target_executable"; then
	write_status "failed:install"
	relaunch_after_cleanup=1
	exit 1
fi

if [ "$appimage_update" -eq 0 ] && [ -f "$stage_dir/THIRD_PARTY_NOTICES.txt" ]; then
	if ! /bin/cp -f "$stage_dir/THIRD_PARTY_NOTICES.txt" "$parent_dir/THIRD_PARTY_NOTICES.txt"; then
		write_status "failed:install"
		relaunch_after_cleanup=1
		exit 1
	fi
fi

write_status "installed"
if relaunch_game; then
	restore_needed=0
	/bin/rm -f "$backup_executable"
else
	write_status "failed:relaunch"
	relaunch_after_cleanup=1
	exit 1
fi
