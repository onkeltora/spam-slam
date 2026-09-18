extends Node2D
## DullOS 98 taskbar at the bottom of the screen.
## The inbox task button doubles as the pile meter (second fail condition),
## so it has to get loud before the collapse. The tray holds the OCQ flower
## (blinks while the boss challenge runs), a WhipAmp visualizer driven by the
## real background music, and a clock running 1 in-game minute per second from 9:00.

const START_WIDTH := 84.0
const INBOX_WIDTH := 330.0
const TRAY_WIDTH := 170.0
const DAY_START_MINUTES := 9 * 60
const EQ_BANDS := 6
const EQ_SMOOTHING := 14.0
const BOSS_RESULT_BLINK := 1.8

## Placement comes from resources/screen_config.tres (taskbar_offset,
## start_button_offset, tray_offset, clock_offset) -- the tube face's rounded corners
## cut into the bar's ends, so the offsets have to be tuned against the same shape.

var _count := 0
var _max := GameManager.PILE_MAX
var _time := 0.0
var _bump := 0.0
var _eq := PackedFloat32Array()
var _boss_active := false
var _boss_result_timer := 0.0
var _app_title := ""


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _ready() -> void:
	GameManager.pile_changed.connect(func(count: int, max_count: int) -> void:
		if count > _count:
			_bump = 1.0
		_count = count
		_max = max_count)
	GameManager.boss_challenge_started.connect(func(_goal: int, _life: bool) -> void: _boss_active = true)
	GameManager.boss_challenge_finished.connect(func(_success: bool) -> void:
		_boss_active = false
		_boss_result_timer = BOSS_RESULT_BLINK)
	GameManager.game_started.connect(func() -> void:
		_boss_active = false
		_boss_result_timer = 0.0)
	GameManager.language_changed.connect(queue_redraw)
	_eq.resize(EQ_BANDS)


## Shows a pressed task button for the open desktop program ("" hides it).
func set_app_title(title: String) -> void:
	_app_title = title


func _process(delta: float) -> void:
	_time += delta
	_bump = move_toward(_bump, 0.0, delta * 5.0)
	_boss_result_timer = maxf(_boss_result_timer - delta, 0.0)
	var target := MusicManager.get_spectrum(EQ_BANDS)
	for i in EQ_BANDS:
		_eq[i] = lerpf(_eq[i], target[i], 1.0 - exp(-EQ_SMOOTHING * delta))
	queue_redraw()


func _draw() -> void:
	var cfg := ScreenLayout.config()
	var bar := ScreenLayout.taskbar_rect()
	bar.position += cfg.taskbar_offset
	draw_rect(bar, ScreenLayout.WINDOW_GREY)
	draw_line(bar.position, Vector2(bar.end.x, bar.position.y), ScreenLayout.BEVEL_LIGHT, 2.0)

	var inner_y := bar.position.y + 4
	var inner_h := bar.size.y - 7

	# Start button
	var start := Rect2(Vector2(bar.position.x, inner_y) + cfg.start_button_offset, Vector2(START_WIDTH, inner_h))
	ScreenLayout.draw_raised(self, start)
	PixelIcons.draw_centered(self, PixelIcons.Icon.ENVELOPE, Vector2(start.position.x + 15, start.get_center().y), 18)
	DrawUtil.text_left(self, tr("OS_START"), Vector2(start.position.x + 28, start.get_center().y), 16,
			ScreenLayout.TEXT_DARK, -1, 1, ScreenLayout.TEXT_DARK)

	var inbox := Rect2(start.end.x + 8, inner_y, INBOX_WIDTH, inner_h)
	_draw_inbox_button(inbox)
	var tray := Rect2(Vector2(bar.end.x - TRAY_WIDTH, inner_y) + cfg.tray_offset, Vector2(TRAY_WIDTH, inner_h))
	if _app_title != "":
		var app := Rect2(inbox.end.x + 6, inner_y, tray.position.x - inbox.end.x - 12, inner_h)
		ScreenLayout.draw_sunken(self, app, Color("dcd9cf"), 1.5)
		DrawUtil.text_left(self, _app_title, Vector2(app.position.x + 8, app.get_center().y),
				DrawUtil.fit_size(_app_title, 15, app.size.x - 16), ScreenLayout.TEXT_DARK, -1, 1, ScreenLayout.TEXT_DARK)

	_draw_tray(tray, cfg.clock_offset)


func _draw_tray(tray: Rect2, clock_offset: Vector2) -> void:
	ScreenLayout.draw_sunken(self, tray, ScreenLayout.WINDOW_GREY, 1.5)
	var cy := tray.get_center().y

	# OCQ flower: dim when idle, blinking while the boss is watching
	var lit := 0.35
	if _boss_active:
		lit = 1.0 if fmod(_time * 2.5, 1.0) < 0.6 else 0.35
	elif _boss_result_timer > 0.0:
		lit = 1.0 if fmod(_time * 6.0, 1.0) < 0.5 else 0.35
	AppIcons.draw_flower(self, Vector2(tray.position.x + 15, cy), 9.0, lit)

	# WhipAmp mini visualizer
	var bolt := Rect2(tray.position.x + 30, cy - 8, 12, 16)
	AppIcons.draw_bolt(self, bolt)
	var eq_x := bolt.end.x + 4
	var eq_h := tray.size.y - 10
	for i in EQ_BANDS:
		var h := maxf(2.0, _eq[i] * eq_h)
		var r := Rect2(eq_x + i * 7, cy + eq_h * 0.5 - h, 5, h)
		draw_rect(r, Color("2fa84f").lerp(Color("f2b12e"), _eq[i]))

	# Clock
	var minutes := DAY_START_MINUTES + int(GameManager.elapsed)
	DrawUtil.text_centered(self, "%d:%02d" % [minutes / 60, minutes % 60], Vector2(tray.end.x - 30, cy) + clock_offset, 15, ScreenLayout.TEXT_DARK)


func _draw_inbox_button(rect: Rect2) -> void:
	var ratio := float(_count) / _max
	var danger := ratio >= 0.75
	var blink := danger and fmod(_time * (4.0 + ratio * 6.0), 1.0) < 0.5

	# Pressed look = active window, flashes red when the inbox is about to crash
	ScreenLayout.draw_sunken(self, rect, Color("e0303a") if blink else Color("dcd9cf"), 1.5)
	var text_color := Color.WHITE if blink else ScreenLayout.TEXT_DARK
	PixelIcons.draw_centered(self, PixelIcons.Icon.ENVELOPE, Vector2(rect.position.x + 14, rect.get_center().y), 18)

	var label := "%s (%d)" % [tr("HUD_INBOX"), _count]
	var slots_width := 120.0
	var label_size := DrawUtil.fit_size(label, int(16 * (1.0 + _bump * 0.2)), rect.size.x - slots_width - 40)
	DrawUtil.text_left(self, label, Vector2(rect.position.x + 28, rect.get_center().y), label_size, text_color, -1, 1, text_color)

	# Fill slots
	var gap := 2.0
	var slot_w := (slots_width - gap * (_max - 1)) / _max
	var slots_x := rect.end.x - slots_width - 8
	for i in _max:
		var r := Rect2(slots_x + i * (slot_w + gap), rect.position.y + 6, slot_w, rect.size.y - 12)
		var t := float(i) / (_max - 1)
		var color := Color("3fae4a").lerp(Color("f2b12e"), clampf(t * 2.0, 0, 1)).lerp(Color("d8202a"), clampf(t * 2.0 - 1.0, 0, 1))
		draw_rect(r, color if i < _count else Color(0, 0, 0, 0.12))
		draw_rect(r, Color(0, 0, 0, 0.35), false, 1.0)
