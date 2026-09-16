class_name RetroWindow
extends Node2D
## Base for the little DullOS programs that open from desktop icons.
## Draws frame, title bar and the classic 98 zoom-out-of-the-icon animation;
## subclasses set `window_rect` in _init and override the draw_* / update_content hooks.

signal closed

const TITLE_HEIGHT := 24.0
const OPEN_TIME := 0.18
const CLOSE_TIME := 0.08
const BUTTON_SIZE := Vector2(18, 16)

var window_rect := Rect2()
## The icon rect the window zooms out of.
var origin_rect := Rect2()
## Time since the open animation finished.
var content_time := 0.0

var _age := 0.0
var _closing := -1.0


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


# --- Hooks for subclasses ---

func get_title() -> String:
	return ""


func get_title_colors() -> Array[Color]:
	return [ScreenLayout.TITLE_BLUE, ScreenLayout.TITLE_BLUE_END]


func draw_title_icon(_center: Vector2) -> void:
	pass


func draw_content(_rect: Rect2) -> void:
	pass


func update_content(_delta: float) -> void:
	pass


func on_closing() -> void:
	pass


## Tap inside the window (world position). Close button is handled before this.
func on_tap(_world_pos: Vector2) -> void:
	pass


# --- Public API ---

func close() -> void:
	if _closing < 0.0:
		_closing = 0.0
		on_closing()


func is_closing() -> bool:
	return _closing >= 0.0


func close_button_rect() -> Rect2:
	var title := title_rect()
	return Rect2(Vector2(title.end.x - 4 - BUTTON_SIZE.x - 3, title.get_center().y - BUTTON_SIZE.y * 0.5), BUTTON_SIZE)


func title_rect() -> Rect2:
	return Rect2(window_rect.position + Vector2(4, 4), Vector2(window_rect.size.x - 8, TITLE_HEIGHT))


func content_rect() -> Rect2:
	return Rect2(window_rect.position + Vector2(6, TITLE_HEIGHT + 8), window_rect.size - Vector2(12, TITLE_HEIGHT + 14))


# --- Internals ---

func _process(delta: float) -> void:
	_age += delta
	if _age >= OPEN_TIME:
		content_time += delta
	if _closing >= 0.0:
		_closing += delta
		if _closing >= CLOSE_TIME:
			closed.emit()
			queue_free()
			return
	update_content(delta)
	queue_redraw()


func _draw() -> void:
	if _age < OPEN_TIME:
		_draw_zoom_outline(_age / OPEN_TIME)
		return
	modulate.a = 1.0 if _closing < 0.0 else 1.0 - _closing / CLOSE_TIME
	draw_window()


## Standard DullOS frame. Skinned programs (WhipAmp) override this completely.
func draw_window() -> void:
	draw_rect(Rect2(window_rect.position + Vector2(8, 10), window_rect.size), Color(0, 0, 0, 0.35))
	ScreenLayout.draw_raised(self, window_rect, ScreenLayout.WINDOW_GREY, 3.0)
	var title := title_rect()
	var colors := get_title_colors()
	ScreenLayout.draw_title_bar(self, title, colors[0], colors[1])
	draw_title_icon(Vector2(title.position.x + 12, title.get_center().y))
	var text := get_title()
	DrawUtil.text_left(self, text, Vector2(title.position.x + 24, title.get_center().y),
			DrawUtil.fit_size(text, 14, title.size.x - 100), Color.WHITE)
	ScreenLayout.draw_window_buttons(self, title, BUTTON_SIZE)
	draw_content(content_rect())


## DullOS "animate windows": a few outline rects zooming from the icon to the window.
func _draw_zoom_outline(k: float) -> void:
	for i in 3:
		var kk := clampf(ease(k, 0.6) - i * 0.18, 0.0, 1.0)
		var r := Rect2(origin_rect.position.lerp(window_rect.position, kk), origin_rect.size.lerp(window_rect.size, kk))
		draw_rect(r, Color(0.08, 0.08, 0.08, 0.8 - i * 0.25), false, 2.0)
