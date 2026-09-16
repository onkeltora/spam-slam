extends Node
## Sound effects (Autoload "SoundManager", instanced from autoload/sound_manager.tscn).
## Open sound_manager.tscn in the editor, unfold a slot and drag files into its `streams`.
## Listens to GameManager itself; plays through a small voice pool on the "SFX" bus
## so fast sounds can overlap instead of cutting each other off.

enum Sound { NEW_POPUP, SORTED, MISTAKE, NEW_RULE, PILE_CRASH, NO_LIVES, COFFEE_BOOST, BONUS, OCQ_MESSAGE,
		APP_OPEN, AOFF_DIALUP }

const BUS_NAME := &"SFX"
const VOICES := 12
## On boss success the OCQ reply comes a moment after the bonus sound, so they don't mask each other.
const OCQ_AFTER_BONUS_DELAY := 0.35

## A new mail moves to the front and becomes readable.
@export var new_popup: SoundEvent
## Mail sorted into the correct folder.
@export var sorted: SoundEvent
## Mail sorted into the wrong folder.
@export var mistake: SoundEvent
## A new special rule – also used when IT swaps two folders.
@export var new_rule: SoundEvent
## Game over: the inbox overflowed (window glitch + bluescreen).
@export var pile_crash: SoundEvent
## Game over: last life lost (monitor powers off).
@export var no_lives: SoundEvent
## Coffee mug full, caffeine boost starts.
@export var coffee_boost: SoundEvent
## Boss challenge completed.
@export var bonus: SoundEvent
## A message from the boss pops up in OCQ (challenge appears, boss replies).
@export var ocq_message: SoundEvent
## A desktop program window opens (double-click on a desktop icon).
@export var app_open: SoundEvent
## AOFF modem dial-up noise. Gets cut off when the window is closed before "line busy".
@export var aoff_dialup: SoundEvent

var _voices: Array[AudioStreamPlayer] = []
var _voice_started_msec: Array[int] = []


func _ready() -> void:
	for i in VOICES:
		var voice := AudioStreamPlayer.new()
		voice.bus = BUS_NAME
		add_child(voice)
		_voices.append(voice)
		_voice_started_msec.append(0)

	GameManager.mail_presented.connect(func(_mail: MailData) -> void: play(Sound.NEW_POPUP))
	GameManager.mail_sorted.connect(_on_mail_sorted)
	GameManager.rule_changed.connect(func(rule: SortRule) -> void:
		if rule != null:
			play(Sound.NEW_RULE))
	GameManager.baskets_swapped.connect(func(_a: int, _b: int) -> void: play(Sound.NEW_RULE))
	GameManager.boost_started.connect(func(_d: float) -> void: play(Sound.COFFEE_BOOST))
	GameManager.boss_challenge_started.connect(func(_goal: int, _life: bool) -> void: play(Sound.OCQ_MESSAGE))
	GameManager.boss_challenge_finished.connect(_on_boss_challenge_finished)
	GameManager.game_over.connect(func(reason: String) -> void:
		play(Sound.PILE_CRASH if reason == "pile" else Sound.NO_LIVES))

	_warn_about_empty_slots()


## Returns the voice that plays the sound (e.g. to stop it early), or null if nothing played.
func play(sound: Sound) -> AudioStreamPlayer:
	var event := get_event(sound)
	if event == null or not event.has_streams():
		return null
	var now := Time.get_ticks_msec()
	if now - event.last_played_msec < event.min_interval * 1000.0:
		return null
	event.last_played_msec = now

	var voice := _free_voice()
	voice.stream = event.pick_stream()
	voice.volume_db = event.volume_db
	var pitch := 1.0 + randf_range(-event.pitch_variation, event.pitch_variation)
	pitch += event.combo_pitch_step * (GameManager.get_multiplier() - 1)
	voice.pitch_scale = maxf(pitch, 0.1)
	voice.play()
	_voice_started_msec[_voices.find(voice)] = now
	return voice


func get_event(sound: Sound) -> SoundEvent:
	match sound:
		Sound.NEW_POPUP:
			return new_popup
		Sound.SORTED:
			return sorted
		Sound.MISTAKE:
			return mistake
		Sound.NEW_RULE:
			return new_rule
		Sound.PILE_CRASH:
			return pile_crash
		Sound.NO_LIVES:
			return no_lives
		Sound.COFFEE_BOOST:
			return coffee_boost
		Sound.BONUS:
			return bonus
		Sound.OCQ_MESSAGE:
			return ocq_message
		Sound.APP_OPEN:
			return app_open
		Sound.AOFF_DIALUP:
			return aoff_dialup
	return null


func _on_boss_challenge_finished(success: bool) -> void:
	if success:
		play(Sound.BONUS)
		get_tree().create_timer(OCQ_AFTER_BONUS_DELAY).timeout.connect(play.bind(Sound.OCQ_MESSAGE))
	elif GameManager.lives > 0:
		# If the fatal mistake ended the challenge, the game over sound has the stage.
		play(Sound.OCQ_MESSAGE)


func _on_mail_sorted(result: Dictionary) -> void:
	if result.correct:
		play(Sound.SORTED)
	elif GameManager.lives > 0:
		# The fatal mistake is covered by the "no lives" sound instead.
		play(Sound.MISTAKE)


## A voice that is idle, otherwise the one that started longest ago.
func _free_voice() -> AudioStreamPlayer:
	var oldest := 0
	for i in _voices.size():
		if not _voices[i].playing:
			return _voices[i]
		if _voice_started_msec[i] < _voice_started_msec[oldest]:
			oldest = i
	return _voices[oldest]


func _warn_about_empty_slots() -> void:
	var empty: Array[String] = []
	for sound in Sound.values():
		var event := get_event(sound)
		if event == null or not event.has_streams():
			empty.append(Sound.keys()[sound].to_lower())
	if not empty.is_empty():
		push_warning("SoundManager: no sounds assigned yet for %s – drag files into autoload/sound_manager.tscn" % ", ".join(empty))
