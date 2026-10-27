#!/bin/sh
set -u

archive="$1"
target_app="$2"
game_pid="$3"
status_file="$4"

write_status() {
	printf '%s\n' "$1" > "$status_file"
}

relaunch_app() {
	if [ -d "$target_app" ]; then
		/usr/bin/open -a "$target_app" >/dev/null 2>&1 || true
	fi
}

while /bin/kill -0 "$game_pid" 2>/dev/null; do
	/bin/sleep 0.25
done

parent_dir=$(/usr/bin/dirname "$target_app")
if [ ! -d "$target_app" ] || [ ! -w "$parent_dir" ]; then
	write_status "failed:folder"
	relaunch_app
	exit 1
fi

stage_dir=$(/usr/bin/mktemp -d "$parent_dir/.captain-tsubasa-update.XXXXXX") || {
	write_status "failed:stage"
	relaunch_app
	exit 1
}
backup_app="${target_app}.update-backup.$$"
restore_needed=0
relaunch_after_cleanup=0

cleanup() {
	if [ "$restore_needed" -eq 1 ] && [ -d "$backup_app" ] && [ ! -d "$target_app" ]; then
		if ! /bin/mv "$backup_app" "$target_app"; then
			write_status "failed:recovery"
		fi
	fi
	/bin/rm -rf "$stage_dir"
	if [ "$relaunch_after_cleanup" -eq 1 ]; then
		relaunch_app
	fi
}
trap cleanup EXIT

if ! /usr/bin/ditto -x -k "$archive" "$stage_dir"; then
	write_status "failed:unpack"
	relaunch_app
	exit 1
fi

new_app=$(/usr/bin/find "$stage_dir" -type d -name '*.app' -prune -print -quit)
if [ -z "$new_app" ] || [ ! -f "$new_app/Contents/Info.plist" ]; then
	write_status "failed:package"
	relaunch_app
	exit 1
fi

bundle_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$new_app/Contents/Info.plist" 2>/dev/null || true)
if [ "$bundle_id" != "com.susimsek.captain-tsubasa-2-remake" ]; then
	write_status "failed:identity"
	relaunch_app
	exit 1
fi

# Keep the existing Gatekeeper state. This updater does not remove quarantine
# or disable macOS security checks.
quarantine=$(/usr/bin/xattr -p com.apple.quarantine "$target_app" 2>/dev/null || true)
if [ -n "$quarantine" ]; then
	/usr/bin/xattr -r -w com.apple.quarantine "$quarantine" "$new_app" || {
		write_status "failed:security"
		relaunch_app
		exit 1
	}
fi

if ! /bin/mv "$target_app" "$backup_app"; then
	write_status "failed:replace"
	relaunch_app
	exit 1
fi
restore_needed=1

if ! /bin/mv "$new_app" "$target_app"; then
	write_status "failed:install"
	relaunch_after_cleanup=1
	exit 1
fi

if [ -f "$stage_dir/THIRD_PARTY_NOTICES.txt" ] && ! /bin/cp -f "$stage_dir/THIRD_PARTY_NOTICES.txt" "$parent_dir/THIRD_PARTY_NOTICES.txt"; then
	/bin/rm -rf "$target_app"
	write_status "failed:install"
	relaunch_after_cleanup=1
	exit 1
fi

write_status "installed"
if ! /usr/bin/open -a "$target_app" >/dev/null 2>&1; then
	/bin/rm -rf "$target_app"
	write_status "failed:relaunch"
	relaunch_after_cleanup=1
	exit 1
fi

restore_needed=0
/bin/rm -rf "$backup_app"
