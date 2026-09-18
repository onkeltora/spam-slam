extends Node
## Window mode, independent of any run (Autoload "DisplayManager"). F11 toggles
## fullscreen/windowed; the choice is remembered across restarts, same
## persist/save_path pattern as MetaProgress/EraManager (own config file, bot
## flips persist off so it never touches the real one).
##
## Canvas stretch stays "expand" (project.godot) -- fullscreen currently just
## reveals more of the desk around the fixed 1280x720 play area, it doesn't
## scale the UI up. That's a separate follow-up if we want mail cards to shrink
## relative to a bigger fullscreen view.

const SAVE_PATH := "user://display.cfg"

var fullscreen := false
var persist := true
var save_path := SAVE_PATH


func _ready() -> void:
	_load()
	_apply()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		toggle()


func toggle() -> void:
	fullscreen = not fullscreen
	_apply()
	if persist:
		_save()


func _apply() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if get_window().is_embedded():
		return  # editor's "Embed Game" view -- only windowed mode is possible there
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		return
	fullscreen = cfg.get_value("display", "fullscreen", false)


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.save(save_path)
