class_name SoundEvent
extends Resource
## One game sound as configured in the SoundManager inspector.
## Drop one or more files into `streams` – with several, a random one is picked each time.

@export var streams: Array[AudioStream] = []
@export_range(-40.0, 12.0, 0.5, "suffix:dB") var volume_db := 0.0
## Random pitch spread, e.g. 0.05 = ±5 %. Keeps frequent sounds from getting grating.
@export_range(0.0, 0.5, 0.01) var pitch_variation := 0.0
## Extra pitch per combo multiplier step above x1 (0 = off). Makes streaks audibly climb.
@export_range(0.0, 0.2, 0.005) var combo_pitch_step := 0.0
## Ignore repeated triggers within this time (avoids stacking in the same frame).
@export_range(0.0, 1.0, 0.01, "suffix:s") var min_interval := 0.03

var last_played_msec := -100000


func has_streams() -> bool:
	return streams.any(func(s: AudioStream) -> bool: return s != null)


func pick_stream() -> AudioStream:
	var valid := streams.filter(func(s: AudioStream) -> bool: return s != null)
	return null if valid.is_empty() else valid.pick_random()
