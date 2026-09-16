class_name AoffDialupWindow
extends RetroWindow
## AOFF sign-on: screen name and password type themselves in, the modem dials,
## connects… and the line is busy. Of course it is.

enum Step { TYPING, INIT, DIALING, CONNECTING, BUSY }

const SIZE := Vector2(430, 318)
const SCREEN_NAME := "DullWorker_2000"
const PASSWORD_LENGTH := 8
const TYPE_NAME_START := 0.25
const TYPE_NAME_END := 1.3
const TYPE_PASS_START := 1.45
const TYPE_PASS_END := 2.05
const DIAL_PRESS := 2.3
const STEP_ENDS := {Step.INIT: 3.0, Step.DIALING: 4.7, Step.CONNECTING: 6.1}
const STEP_KEYS := {
	Step.INIT: "AOFF_STEP_INIT",
	Step.DIALING: "AOFF_STEP_DIAL",
	Step.CONNECTING: "AOFF_STEP_CONNECT",
	Step.BUSY: "AOFF_BUSY",
}

var _dial_voice: AudioStreamPlayer = null
var _dial_started := false


func _init() -> void:
	window_rect = Rect2(ScreenLayout.DESKTOP_RECT.get_center() - SIZE * 0.5, SIZE)


func get_title() -> String:
	return tr("AOFF_WINDOW_TITLE")


func draw_title_icon(center: Vector2) -> void:
	AppIcons.draw_triangle_man(self, center, 8.0)


func update_content(_delta: float) -> void:
	if not _dial_started and content_time >= DIAL_PRESS:
		_dial_started = true
		_dial_voice = SoundManager.play(SoundManager.Sound.AOFF_DIALUP)


func on_closing() -> void:
	# Hanging up mid-dial cuts the modem noise.
	if _dial_voice != null and _dial_voice.playing and current_step() != Step.BUSY:
		_dial_voice.stop()


func current_step() -> Step:
	var t := content_time
	if t < DIAL_PRESS:
		return Step.TYPING
	for step in [Step.INIT, Step.DIALING, Step.CONNECTING]:
		if t < STEP_ENDS[step]:
			return step
	return Step.BUSY


func draw_content(rect: Rect2) -> void:
	var t := content_time
	var x := rect.position.x
	var y := rect.position.y
	var w := rect.size.x

	# Branding
	AppIcons.draw_triangle_man(self, Vector2(x + 50, y + 48), 36.0)
	DrawUtil.text_left(self, "AOFF", Vector2(x + 100, y + 30), 30, Color("1d4fb0"), -1, 2, Color("1d4fb0"))
	DrawUtil.text_left(self, "America Offline", Vector2(x + 100, y + 58), 17, ScreenLayout.TEXT_DARK)
	DrawUtil.text_left(self, "Version 5.0", Vector2(x + 100, y + 78), 12, Color("55524a"))

	# Fields typing themselves
	var name_chars := int(clampf(inverse_lerp(TYPE_NAME_START, TYPE_NAME_END, t), 0.0, 1.0) * SCREEN_NAME.length())
	var pass_chars := int(clampf(inverse_lerp(TYPE_PASS_START, TYPE_PASS_END, t), 0.0, 1.0) * PASSWORD_LENGTH)
	var cursor_on := fmod(t, 0.8) < 0.4
	var name_active := t < TYPE_PASS_START
	var pass_active := not name_active and t < DIAL_PRESS
	_draw_field(Vector2(x + 16, y + 120), w - 32, tr("AOFF_SCREEN_NAME"), SCREEN_NAME.substr(0, name_chars), name_active and cursor_on)
	_draw_field(Vector2(x + 16, y + 156), w - 32, tr("AOFF_PASSWORD"), "•".repeat(pass_chars), pass_active and cursor_on)

	# Status line + segmented progress bar
	var step := current_step()
	var bar := Rect2(x + 16, y + 206, w - 32, 18)
	if step != Step.TYPING:
		var status_color := Color("c0201a") if step == Step.BUSY else ScreenLayout.TEXT_DARK
		var dots := ".".repeat(int(t * 3.0) % 4) if step != Step.BUSY else ""
		var status := tr(STEP_KEYS[step]) + dots
		DrawUtil.text_left(self, status, Vector2(x + 16, y + 190), DrawUtil.fit_size(status, 15, w - 32), status_color, -1,
				1 if step == Step.BUSY else 0, status_color)
		_draw_progress(bar, _progress(t), step == Step.BUSY)
	else:
		ScreenLayout.draw_sunken(self, bar, ScreenLayout.WINDOW_GREY, 1.5)

	# Buttons
	var dialing := step != Step.TYPING and step != Step.BUSY
	var sign_on := Rect2(x + w * 0.5 - 150, rect.end.y - 40, 140, 30)
	var cancel := Rect2(x + w * 0.5 + 10, rect.end.y - 40, 140, 30)
	_draw_button(sign_on, tr("AOFF_SIGN_ON"), dialing or (t >= DIAL_PRESS - 0.12 and t < DIAL_PRESS + 0.1))
	_draw_button(cancel, tr("AOFF_CANCEL"), false)


func _progress(t: float) -> float:
	if t < DIAL_PRESS:
		return 0.0
	if t >= STEP_ENDS[Step.CONNECTING]:
		return 0.85
	return clampf(inverse_lerp(DIAL_PRESS, STEP_ENDS[Step.CONNECTING], t), 0.0, 1.0) * 0.85


func _draw_field(pos: Vector2, width: float, label: String, text: String, cursor: bool) -> void:
	DrawUtil.text_left(self, label, Vector2(pos.x, pos.y), 15, ScreenLayout.TEXT_DARK)
	var field := Rect2(pos.x + 136, pos.y - 13, width - 136, 26)
	ScreenLayout.draw_sunken(self, field, Color.WHITE)
	DrawUtil.text_left(self, text, Vector2(field.position.x + 6, field.get_center().y), 16, ScreenLayout.TEXT_DARK)
	if cursor:
		var cx := field.position.x + 7 + DrawUtil.text_width(text, 16)
		draw_line(Vector2(cx, field.position.y + 5), Vector2(cx, field.end.y - 5), ScreenLayout.TEXT_DARK, 1.5)


func _draw_progress(bar: Rect2, fill: float, failed: bool) -> void:
	ScreenLayout.draw_sunken(self, bar, Color.WHITE, 1.5)
	var inner := bar.grow(-3)
	var block := 9.0
	var count := int(inner.size.x * fill / (block + 2.0))
	for i in count:
		draw_rect(Rect2(inner.position.x + i * (block + 2.0), inner.position.y, block, inner.size.y),
				Color("c0201a") if failed else Color("1d2b73"))


func _draw_button(rect: Rect2, label: String, pressed: bool) -> void:
	if pressed:
		ScreenLayout.draw_sunken(self, rect, ScreenLayout.WINDOW_GREY)
	else:
		ScreenLayout.draw_raised(self, rect)
	DrawUtil.text_centered(self, label, rect.get_center() + (Vector2(1, 1) if pressed else Vector2.ZERO), 15, ScreenLayout.TEXT_DARK)
