extends Node
## Background music (Autoload "MusicManager", instanced from autoload/music_manager.tscn).
## Open music_manager.tscn in the editor and drag tracks into `playlist` in the inspector.
## Plays the playlist in order (or shuffled) on the "Music" bus and sounds muffled
## (low-pass + a bit quieter) outside of a run, i.e. on the title and game over screens.

const BUS_NAME := &"Music"
const SILENT_DB := -60.0
const OPEN_CUTOFF_HZ := 20500.0
const SPECTRUM_MIN_HZ := 40.0
const SPECTRUM_MAX_HZ := 8000.0
const SPECTRUM_FLOOR_DB := -48.0  # band level shown as empty...
const SPECTRUM_CEIL_DB := -12.0   # ...and as full (music usually sits around -25..-40 dB per band)

@export var playlist: Array[AudioStream] = []
@export var shuffle := false
@export var autoplay := true
@export_range(-40.0, 6.0, 0.5, "suffix:dB") var volume_db := -6.0
@export_range(0.0, 5.0, 0.1, "suffix:s") var fade_in_time := 2.0

@export_group("Muffle (title / game over)")
@export var muffle_outside_run := true
@export_range(200.0, 5000.0, 10.0, "suffix:Hz") var muffled_cutoff_hz := 900.0
@export_range(-20.0, 0.0, 0.5, "suffix:dB") var muffled_volume_offset_db := -4.0
@export_range(0.0, 3.0, 0.05, "suffix:s") var muffle_fade_time := 0.8

@onready var player: AudioStreamPlayer = $Player

var _order: Array[int] = []
var _order_pos := -1
var _base_db := SILENT_DB      # fade in/out volume, before the muffle offset
var _muffle := 0.0             # 0 = clear, 1 = fully muffled
var _bus_index := -1
var _lowpass_index := -1
var _analyzer: AudioEffectSpectrumAnalyzerInstance
var _fade_tween: Tween
var _muffle_tween: Tween


func _ready() -> void:
	_setup_bus()
	player.bus = BUS_NAME
	player.finished.connect(_play_next)
	GameManager.game_started.connect(set_muffled.bind(false))
	GameManager.game_over.connect(func(_reason: String) -> void: set_muffled(true))
	_set_muffle(1.0 if muffle_outside_run else 0.0)
	if autoplay:
		play()


## Starts the playlist from the beginning with a fade-in.
func play() -> void:
	_build_order()
	if _order.is_empty():
		push_warning("MusicManager: playlist is empty – drag tracks into autoload/music_manager.tscn")
		return
	_order_pos = -1
	_base_db = SILENT_DB
	_apply_volume()
	_play_next()
	_fade_to(volume_db, fade_in_time)


func stop(fade_time: float = 1.0) -> void:
	_fade_to(SILENT_DB, fade_time)
	_fade_tween.tween_callback(func() -> void:
		player.stop()
		player.stream_paused = false)


## Actively playing (false while paused – Godot reports a paused player as not playing).
func is_playing() -> bool:
	return player.playing


# --- Player controls (used by the WhipAmp desktop program) ---

## Unpauses, or restarts the current track after a stop (starts the playlist if nothing ran yet).
func resume() -> void:
	if player.stream_paused:
		player.stream_paused = false
		return
	if player.playing:
		return
	if _order.is_empty() or _order_pos < 0:
		play()
		return
	_base_db = SILENT_DB
	_apply_volume()
	_start_current()
	_fade_to(volume_db, 0.3)


func pause() -> void:
	if player.playing:
		player.stream_paused = true


func is_paused() -> bool:
	return player.stream_paused and player.stream != null


func next_track() -> void:
	if _order.is_empty():
		play()
		return
	_prepare_skip()
	_play_next()


func previous_track() -> void:
	if _order.is_empty():
		play()
		return
	_prepare_skip()
	_order_pos = posmod(_order_pos - 1, _order.size())
	_start_current()


## File name of the current track without extension, e.g. "Spam Slam V8 - Simple ONE MINUTE".
func get_track_title() -> String:
	if player.stream == null:
		return ""
	var file_name := player.stream.resource_path.get_file().get_basename()
	return file_name if file_name != "" else "Track %d" % get_track_number()


func get_track_number() -> int:
	return maxi(_order_pos, 0) + 1


func get_position() -> float:
	return player.get_playback_position() if (player.playing or is_paused()) else 0.0


func get_length() -> float:
	return player.stream.get_length() if player.stream != null else 0.0


## Jump to a point in the current track (0..1).
func seek(ratio: float) -> void:
	if (player.playing or is_paused()) and get_length() > 0.0:
		player.seek(clampf(ratio, 0.0, 0.999) * get_length())


## Player volume 0..1 on the Music bus (independent of fades and muffling).
func set_user_volume(linear: float) -> void:
	AudioServer.set_bus_volume_db(_bus_index, linear_to_db(maxf(clampf(linear, 0.0, 1.0), 0.0001)))


func get_user_volume() -> float:
	return clampf(db_to_linear(AudioServer.get_bus_volume_db(_bus_index)), 0.0, 1.0)


## Loudness per band (0..1), log-spaced from bass to treble, measured after the
## muffle filter – for visualizers like the WhipAmp one in the taskbar.
func get_spectrum(bands: int) -> PackedFloat32Array:
	var levels := PackedFloat32Array()
	levels.resize(bands)
	if _analyzer == null or not player.playing:
		return levels
	var from_hz := SPECTRUM_MIN_HZ
	for i in bands:
		var to_hz := SPECTRUM_MIN_HZ * pow(SPECTRUM_MAX_HZ / SPECTRUM_MIN_HZ, float(i + 1) / bands)
		var magnitude := _analyzer.get_magnitude_for_frequency_range(from_hz, to_hz).length()
		levels[i] = clampf(inverse_lerp(SPECTRUM_FLOOR_DB, SPECTRUM_CEIL_DB, linear_to_db(magnitude)), 0.0, 1.0)
		from_hz = to_hz
	return levels


func set_muffled(muffled: bool) -> void:
	var target := 1.0 if (muffled and muffle_outside_run) else 0.0
	if _muffle_tween:
		_muffle_tween.kill()
	_muffle_tween = create_tween()
	_muffle_tween.tween_method(_set_muffle, _muffle, target, muffle_fade_time)


# --- Playlist ---

func _build_order(avoid_first: int = -1) -> void:
	_order.clear()
	for i in playlist.size():
		if playlist[i] != null:  # empty inspector slots are skipped
			_order.append(i)
	if shuffle and _order.size() > 1:
		_order.shuffle()
		if _order[0] == avoid_first:  # never the same track twice in a row
			_order.push_back(_order.pop_front())
	var single := _order.size() == 1
	for i in _order:
		_configure_loop(playlist[i], single)


func _play_next() -> void:
	if _order.is_empty():
		return
	_order_pos += 1
	if _order_pos >= _order.size():
		_build_order(_order.back())
		_order_pos = 0
		if _order.is_empty():
			return
	_start_current()


func _start_current() -> void:
	player.stream = playlist[_order[_order_pos]]
	player.stream_paused = false
	player.play()


## Skipping during a fade-out/-in jumps straight to normal volume.
func _prepare_skip() -> void:
	if _fade_tween:
		_fade_tween.kill()
	_base_db = volume_db
	_apply_volume()


## One track: loop seamlessly (OGG/MP3). Several tracks: disable looping so `finished`
## fires and the playlist advances, even if the track was imported with loop enabled.
func _configure_loop(stream: AudioStream, loop: bool) -> void:
	if stream is AudioStreamWAV:
		if not loop:
			stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	elif "loop" in stream:
		stream.loop = loop


# --- Volume & muffle ---

func _fade_to(target_db: float, time: float) -> void:
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_method(_set_base_db, _base_db, target_db, maxf(time, 0.01))


func _set_base_db(value: float) -> void:
	_base_db = value
	_apply_volume()


func _set_muffle(value: float) -> void:
	_muffle = value
	var lowpass := AudioServer.get_bus_effect(_bus_index, _lowpass_index) as AudioEffectLowPassFilter
	# Interpolate in log space so the sweep sounds even.
	lowpass.cutoff_hz = OPEN_CUTOFF_HZ * pow(muffled_cutoff_hz / OPEN_CUTOFF_HZ, value)
	AudioServer.set_bus_effect_enabled(_bus_index, _lowpass_index, value > 0.001)
	_apply_volume()


func _apply_volume() -> void:
	player.volume_db = _base_db + muffled_volume_offset_db * _muffle


## Uses the "Music" bus from default_bus_layout.tres; creates bus, low-pass and
## spectrum analyzer if missing (analyzer after the low-pass).
func _setup_bus() -> void:
	_bus_index = AudioServer.get_bus_index(BUS_NAME)
	if _bus_index == -1:
		_bus_index = AudioServer.bus_count
		AudioServer.add_bus()
		AudioServer.set_bus_name(_bus_index, BUS_NAME)
		AudioServer.set_bus_send(_bus_index, &"Master")
	_lowpass_index = _find_or_add_effect(AudioEffectLowPassFilter)
	var analyzer_index := _find_or_add_effect(AudioEffectSpectrumAnalyzer)
	_analyzer = AudioServer.get_bus_effect_instance(_bus_index, analyzer_index) as AudioEffectSpectrumAnalyzerInstance


func _find_or_add_effect(type: Variant) -> int:
	for i in AudioServer.get_bus_effect_count(_bus_index):
		if is_instance_of(AudioServer.get_bus_effect(_bus_index, i), type):
			return i
	AudioServer.add_bus_effect(_bus_index, type.new())
	return AudioServer.get_bus_effect_count(_bus_index) - 1
