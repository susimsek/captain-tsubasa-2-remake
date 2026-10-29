#!/bin/sh
set -u

archive="$1"
target_executable="$2"
game_pid="$3"
status_file="$4"
package_kind="${5:-archive}"
appimage_update=0

# Keep this list in sync with the Linux tarball contents in .github/workflows/release.yml.
archive_files="
captain-tsubasa-2-remake.x86_64
THIRD_PARTY_NOTICES.txt
captain-tsubasa-2-icon.png
install-desktop-entry.sh
uninstall-desktop-entry.sh
"

write_status() {
	printf '%s\n' "$1" > "$status_file"
}

case "$package_kind" in
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
temporary_archive_file="$parent_dir/.captain-tsubasa-update.$$.new"
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
archive_backup_dir="$stage_dir/backup"
archive_absent_dir="$stage_dir/absent"
rollback_required=0
relaunch_after_cleanup=0
preserve_stage=0
recovery_failed=0

rollback_archive_files() {
	rollback_failed=0
	for package_file in $archive_files; do
		target_file="$parent_dir/$package_file"
		backup_file="$archive_backup_dir/$package_file"
		absent_marker="$archive_absent_dir/$package_file"
		if [ -f "$backup_file" ]; then
			if ! /bin/mv -f "$backup_file" "$target_file"; then
				rollback_failed=1
			fi
		elif [ -f "$absent_marker" ]; then
			if ! /bin/rm -f "$target_file"; then
				rollback_failed=1
			fi
		fi
	done
	return "$rollback_failed"
}

cleanup() {
	if [ "$rollback_required" -eq 1 ]; then
		if [ "$appimage_update" -eq 1 ]; then
			if [ ! -f "$backup_executable" ] || ! /bin/cp -f "$backup_executable" "$target_executable" || ! /bin/chmod +x "$target_executable"; then
				recovery_failed=1
			fi
		elif ! rollback_archive_files; then
			recovery_failed=1
		fi
	fi

	if [ "$recovery_failed" -eq 1 ]; then
		write_status "failed:recovery"
		preserve_stage=1
	fi
	/bin/rm -f "$temporary_executable" "$temporary_archive_file"
	if [ "$preserve_stage" -eq 0 ]; then
		/bin/rm -rf "$stage_dir"
		/bin/rm -f "$backup_executable"
	fi
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
	if ! /bin/cp -f "$target_executable" "$backup_executable"; then
		write_status "failed:backup"
		relaunch_after_cleanup=1
		exit 1
	fi
	rollback_required=1
	if ! /bin/cp -f "$new_executable" "$temporary_executable" || ! /bin/chmod +x "$temporary_executable" || ! /bin/mv -f "$temporary_executable" "$target_executable"; then
		write_status "failed:install"
		relaunch_after_cleanup=1
		exit 1
	fi
else
	if ! /bin/tar -xzf "$archive" -C "$stage_dir" --no-same-owner --no-same-permissions -- \
		captain-tsubasa-2-remake.x86_64 THIRD_PARTY_NOTICES.txt \
		captain-tsubasa-2-icon.png install-desktop-entry.sh uninstall-desktop-entry.sh; then
		write_status "failed:unpack"
		relaunch_after_cleanup=1
		exit 1
	fi

	for package_file in $archive_files; do
		staged_file="$stage_dir/$package_file"
		if [ ! -f "$staged_file" ] || [ -L "$staged_file" ]; then
			write_status "failed:package"
			relaunch_after_cleanup=1
			exit 1
		fi
	done

	if ! /bin/mkdir "$archive_backup_dir" "$archive_absent_dir"; then
		write_status "failed:stage"
		relaunch_after_cleanup=1
		exit 1
	fi

	# Check every destination before moving any package file aside.
	for package_file in $archive_files; do
		target_file="$parent_dir/$package_file"
		if [ -L "$target_file" ] || { [ -e "$target_file" ] && [ ! -f "$target_file" ]; }; then
			write_status "failed:folder"
			relaunch_after_cleanup=1
			exit 1
		fi
	done

	rollback_required=1
	for package_file in $archive_files; do
		target_file="$parent_dir/$package_file"
		if [ -f "$target_file" ]; then
			if ! /bin/mv "$target_file" "$archive_backup_dir/$package_file"; then
				write_status "failed:backup"
				relaunch_after_cleanup=1
				exit 1
			fi
		elif ! : > "$archive_absent_dir/$package_file"; then
			write_status "failed:backup"
			relaunch_after_cleanup=1
			exit 1
		fi
	done

	for package_file in $archive_files; do
		staged_file="$stage_dir/$package_file"
		target_file="$parent_dir/$package_file"
		if ! /bin/cp -p "$staged_file" "$temporary_archive_file"; then
			write_status "failed:install"
			relaunch_after_cleanup=1
			exit 1
		fi
		case "$package_file" in
			captain-tsubasa-2-remake.x86_64|install-desktop-entry.sh|uninstall-desktop-entry.sh)
				if ! /bin/chmod +x "$temporary_archive_file"; then
					write_status "failed:install"
					relaunch_after_cleanup=1
					exit 1
				fi
				;;
		esac
		if ! /bin/mv -f "$temporary_archive_file" "$target_file"; then
			write_status "failed:install"
			relaunch_after_cleanup=1
			exit 1
		fi
	done
fi

write_status "installed"
if relaunch_game; then
	rollback_required=0
	/bin/rm -f "$backup_executable"
else
	write_status "failed:relaunch"
	relaunch_after_cleanup=1
	exit 1
fi
