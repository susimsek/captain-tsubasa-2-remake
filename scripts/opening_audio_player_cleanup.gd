extends AudioStreamPlayer
## Release the WAV playback before this child node exits the scene tree.

var _playback_expected_active := false


func set_playback_expected_active(active: bool) -> void:
	_playback_expected_active = active


func playback_expected_active() -> bool:
	return _playback_expected_active


func _exit_tree() -> void:
	var had_active_playback := _playback_expected_active
	AudioServer.lock()
	if had_active_playback:
		stop()
	_playback_expected_active = false
	stream = null
	AudioServer.unlock()
	if had_active_playback:
		OS.delay_msec(50)
