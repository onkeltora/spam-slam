class_name AppWindows
extends Node2D
## Opens the little DullOS programs when a desktop icon is double-clicked.
## At most one program window at a time. The game keeps running while it is open –
## procrastination costs inbox space. Drag your own cat picture into `cat_picture`.

signal window_changed(task_title: String)  # "" = no program open

const APPS_WITH_WINDOWS := ["cat", "aoff", "ocq", "whipamp"]

@export var cat_picture: Texture2D

var current: RetroWindow = null
## Boss messages of the current run for the OCQ history: {"goal": int} or {"success": bool}.
var boss_history: Array[Dictionary] = []


func _ready() -> void:
	GameManager.game_started.connect(func() -> void:
		boss_history.clear()
		close_window(true))
	GameManager.game_over.connect(func(_reason: String) -> void: close_window(true))
	GameManager.boss_challenge_started.connect(func(goal: int, _life: bool) -> void: boss_history.append({"goal": goal}))
	GameManager.boss_challenge_finished.connect(func(success: bool) -> void: boss_history.append({"success": success}))
	GameManager.language_changed.connect(func() -> void:
		if is_open():
			window_changed.emit(current.get_title()))


func is_open() -> bool:
	return current != null and not current.is_closing()


## Returns false for icons without a program.
func open_app(app_id: String, origin: Rect2) -> bool:
	if app_id not in APPS_WITH_WINDOWS:
		return false
	close_window(true)
	var window: RetroWindow
	match app_id:
		"cat":
			var viewer := CatViewerWindow.new()
			viewer.picture = cat_picture
			window = viewer
		"aoff":
			window = AoffDialupWindow.new()
		"ocq":
			var ocq := OcqWindow.new()
			ocq.history = boss_history
			window = ocq
		"whipamp":
			window = WhipAmpWindow.new()
	window.origin_rect = origin
	window.closed.connect(func() -> void:
		if current == window:
			current = null
			window_changed.emit(""))
	add_child(window)
	current = window
	window_changed.emit(window.get_title())
	SoundManager.play(SoundManager.Sound.APP_OPEN)
	return true


func close_window(immediate: bool = false) -> void:
	if current == null:
		return
	if immediate:
		current.on_closing()
		current.queue_free()
		current = null
		window_changed.emit("")
	else:
		current.close()


## Handles a tap on the screen. Returns true if the open window consumed it.
func handle_tap(world_pos: Vector2) -> bool:
	if not is_open():
		return false
	if current.close_button_rect().grow(4.0).has_point(world_pos):
		close_window()
		return true
	if current.window_rect.has_point(world_pos):
		current.on_tap(world_pos)
		return true
	return false
