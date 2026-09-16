class_name WhipAmpWindow
extends RetroWindow
## WhipAmp: a skinned music player in the style of the legendary one. It really controls
## the MusicManager – prev/play/pause/stop/next, seek bar and volume – and shows the real
## track name, time and a spectrum of the background music.

const SIZE := Vector2(480, 212)
const BANDS := 19
const MARQUEE_SPEED := 40.0
const PEAK_FALL := 0.6            # per second
const BUTTON_FLASH := 0.14
const BUTTONS := ["prev", "play", "pause", "stop", "next"]

const BODY_TOP := Color("3c3c50")
const BODY_BOTTOM := Color("20202c")
const EDGE_LIGHT := Color("6c6c84")
const EDGE_DARK := Color("0c0c14")
const LCD := Color("050a05")
const LCD_GREEN := Color("2cff4a")
const LCD_DIM := Color("0f4a18")
const GOLD := Color("d8c070")

var _levels := PackedFloat32Array()
var _peaks := PackedFloat32Array()
var _marquee_offset := 0.0
var _pressed := ""
var _pressed_timer := 0.0


func _init() -> void:
	var desktop := ScreenLayout.DESKTOP_RECT
	window_rect = Rect2(Vector2(desktop.get_center().x - SIZE.x * 0.5, desktop.position.y + 150), SIZE)
	_levels.resize(BANDS)
	_peaks.resize(BANDS)


func get_title() -> String:
	return "WhipAmp"


func close_button_rect() -> Rect2:
	return Rect2(window_rect.position + Vector2(SIZE.x - 20, 5), Vector2(13, 12))


# --- Layout (shared by drawing and tapping) ---

func _lcd_rect() -> Rect2:
	return Rect2(window_rect.position + Vector2(10, 26), Vector2(172, 90))


func _marquee_rect() -> Rect2:
	return Rect2(window_rect.position + Vector2(192, 26), Vector2(SIZE.x - 202, 24))


func _volume_rect() -> Rect2:
	return Rect2(window_rect.position + Vector2(192, 90), Vector2(170, 12))


func _seek_rect() -> Rect2:
	return Rect2(window_rect.position + Vector2(10, 126), Vector2(SIZE.x - 20, 12))


func _button_rect(index: int) -> Rect2:
	return Rect2(window_rect.position + Vector2(10 + index * 44, 150), Vector2(40, 28))


# --- Behaviour ---

func update_content(delta: float) -> void:
	_marquee_offset += MARQUEE_SPEED * delta
	_pressed_timer = maxf(_pressed_timer - delta, 0.0)
	var target := MusicManager.get_spectrum(BANDS)
	for i in BANDS:
		_levels[i] = lerpf(_levels[i], target[i], 1.0 - exp(-18.0 * delta))
		_peaks[i] = maxf(_levels[i], _peaks[i] - PEAK_FALL * delta)


func on_tap(world_pos: Vector2) -> void:
	for i in BUTTONS.size():
		if _button_rect(i).grow(2.0).has_point(world_pos):
			_press(BUTTONS[i])
			return
	var volume := _volume_rect().grow_individual(0, 8, 0, 8)
	if volume.has_point(world_pos):
		MusicManager.set_user_volume((world_pos.x - volume.position.x) / volume.size.x)
		return
	var seek := _seek_rect().grow_individual(0, 8, 0, 8)
	if seek.has_point(world_pos):
		MusicManager.seek((world_pos.x - seek.position.x) / seek.size.x)


func _press(button: String) -> void:
	_pressed = button
	_pressed_timer = BUTTON_FLASH
	match button:
		"prev":
			MusicManager.previous_track()
		"play":
			MusicManager.resume()
		"pause":
			if MusicManager.is_paused():
				MusicManager.resume()
			else:
				MusicManager.pause()
		"stop":
			MusicManager.stop(0.15)
		"next":
			MusicManager.next_track()


# --- Drawing ---

func draw_window() -> void:
	var r := window_rect
	draw_rect(Rect2(r.position + Vector2(8, 10), r.size), Color(0, 0, 0, 0.4))
	draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
			PackedColorArray([BODY_TOP, BODY_TOP, BODY_BOTTOM, BODY_BOTTOM]))
	draw_line(r.position, Vector2(r.end.x, r.position.y), EDGE_LIGHT, 2.0)
	draw_line(r.position, Vector2(r.position.x, r.end.y), EDGE_LIGHT, 2.0)
	draw_line(r.end, Vector2(r.position.x, r.end.y), EDGE_DARK, 2.0)
	draw_line(r.end, Vector2(r.end.x, r.position.y), EDGE_DARK, 2.0)

	_draw_title_strip()
	_draw_lcd()
	_draw_marquee()
	_draw_info_and_volume()
	_draw_seek_bar()
	for i in BUTTONS.size():
		_draw_button(i)
	_draw_logo()


func _draw_title_strip() -> void:
	var strip := Rect2(window_rect.position + Vector2(4, 4), Vector2(SIZE.x - 8, 15))
	draw_rect(strip, Color("15151f"))
	var label := "WHIPAMP"
	var label_w := DrawUtil.text_width(label, 11) + 16
	var cx := strip.get_center().x
	for side in [-1, 1]:
		var from_x: float = cx + side * label_w * 0.5
		var to_x: float = strip.position.x + 6 if side < 0 else strip.end.x - 26
		for row in 2:
			var y := strip.position.y + 5 + row * 4
			draw_line(Vector2(from_x, y), Vector2(to_x, y), GOLD.darkened(0.45), 1.0)
	DrawUtil.text_centered(self, label, strip.get_center(), 11, GOLD)
	var close := close_button_rect()
	draw_rect(close, Color("2c2c3c"))
	draw_rect(close, EDGE_LIGHT, false, 1.0)
	var c := close.get_center()
	draw_line(c + Vector2(-3, -3), c + Vector2(3, 3), GOLD, 1.5)
	draw_line(c + Vector2(3, -3), c + Vector2(-3, 3), GOLD, 1.5)


func _draw_lcd() -> void:
	var lcd := _lcd_rect()
	_draw_inset(lcd, LCD)

	# Play state symbol
	var s := Vector2(lcd.position.x + 16, lcd.position.y + 20)
	if MusicManager.is_paused():
		draw_rect(Rect2(s + Vector2(-5, -7), Vector2(4, 14)), LCD_GREEN)
		draw_rect(Rect2(s + Vector2(2, -7), Vector2(4, 14)), LCD_GREEN)
	elif MusicManager.is_playing():
		draw_colored_polygon(PackedVector2Array([s + Vector2(-5, -7), s + Vector2(7, 0), s + Vector2(-5, 7)]), LCD_GREEN)
	else:
		draw_rect(Rect2(s - Vector2(6, 6), Vector2(12, 12)), LCD_GREEN)

	# Time (blinks while paused, like the original)
	var seconds := int(MusicManager.get_position())
	var time_text := "%d:%02d" % [seconds / 60, seconds % 60]
	if not MusicManager.is_paused() or fmod(content_time, 1.0) < 0.6:
		var time_pos := Vector2(lcd.end.x - 12 - DrawUtil.text_width(time_text, 30), lcd.position.y + 22)
		DrawUtil.text_left(self, time_text, time_pos + Vector2(1, 1), 30, Color(LCD_GREEN, 0.25))
		DrawUtil.text_left(self, time_text, time_pos, 30, LCD_GREEN)

	# Spectrum with falling peak caps
	var area := Rect2(lcd.position.x + 8, lcd.position.y + 44, lcd.size.x - 16, lcd.size.y - 50)
	var bar_w := area.size.x / BANDS
	for i in BANDS:
		var x := area.position.x + i * bar_w
		var h := _levels[i] * area.size.y
		var segments := int(h / 3.0)
		for seg in segments:
			var t := float(seg * 3) / area.size.y
			var color := Color("2cd84a").lerp(Color("f2d22e"), clampf(t * 1.8, 0, 1)).lerp(Color("e8402a"), clampf(t * 2.2 - 1.2, 0, 1))
			draw_rect(Rect2(x, area.end.y - (seg + 1) * 3.0, bar_w - 1.5, 2.0), color)
		if _peaks[i] > 0.02:
			draw_rect(Rect2(x, area.end.y - _peaks[i] * area.size.y - 2.0, bar_w - 1.5, 1.5), Color("b8b8c8"))


func _draw_marquee() -> void:
	var box := _marquee_rect()
	_draw_inset(box, LCD)
	var title := MusicManager.get_track_title()
	var text: String
	if title == "":
		text = "WhipAmp 2.91  ***  "
	else:
		var length := int(MusicManager.get_length())
		text = "%d. %s (%d:%02d)  ***  " % [MusicManager.get_track_number(), title, length / 60, length % 60]
	# Draw character by character and only fully visible ones – a poor man's clip rect.
	var f := DrawUtil.font()
	var size := 15
	var widths := PackedFloat32Array()
	var total := 0.0
	for ch in text:
		var w := f.get_char_size(ch.unicode_at(0), size).x
		widths.append(w)
		total += w
	if total <= 0.0:
		return
	var x := box.position.x + 4 - fmod(_marquee_offset, total)
	var baseline := box.get_center().y + (f.get_ascent(size) - f.get_descent(size)) * 0.5
	for _repeat in 3:
		for i in text.length():
			if x >= box.position.x + 2 and x + widths[i] <= box.end.x - 2:
				draw_char(f, Vector2(x, baseline), text[i], size, LCD_GREEN)
			x += widths[i]
			if x > box.end.x:
				return


func _draw_info_and_volume() -> void:
	var y := window_rect.position.y + 62
	var x := window_rect.position.x + 192
	for label in ["128 kbps", "44 kHz"]:
		var w := DrawUtil.text_width(label, 12) + 12
		var box := Rect2(x, y - 9, w, 18)
		_draw_inset(box, LCD)
		DrawUtil.text_centered(self, label, box.get_center(), 12, LCD_GREEN)
		x += w + 6
	DrawUtil.text_left(self, "stereo", Vector2(x + 4, y), 12, LCD_GREEN if MusicManager.is_playing() else LCD_DIM)

	var vol := _volume_rect()
	var level := MusicManager.get_user_volume()
	_draw_inset(vol, Color("101018"))
	draw_polygon(PackedVector2Array([vol.position + Vector2(2, 2), Vector2(vol.position.x + 2 + (vol.size.x - 4) * level, vol.position.y + 2),
			Vector2(vol.position.x + 2 + (vol.size.x - 4) * level, vol.end.y - 2), Vector2(vol.position.x + 2, vol.end.y - 2)]),
			PackedColorArray([Color("2cd84a"), Color("2cd84a").lerp(Color("e8402a"), level), Color("2cd84a").lerp(Color("e8402a"), level), Color("2cd84a")]))
	var thumb := Rect2(vol.position.x + (vol.size.x - 14) * level, vol.position.y - 3, 14, vol.size.y + 6)
	_draw_metal(thumb, false)
	DrawUtil.text_left(self, "VOL", Vector2(vol.end.x + 8, vol.get_center().y), 11, GOLD)


func _draw_seek_bar() -> void:
	var bar := _seek_rect()
	_draw_inset(bar, Color("101018"))
	var length := MusicManager.get_length()
	var ratio := MusicManager.get_position() / length if length > 0.0 else 0.0
	var thumb := Rect2(bar.position.x + (bar.size.x - 30) * clampf(ratio, 0, 1), bar.position.y - 2, 30, bar.size.y + 4)
	_draw_metal(thumb, false)


func _draw_button(index: int) -> void:
	var rect := _button_rect(index)
	var button: String = BUTTONS[index]
	var pressed := _pressed == button and _pressed_timer > 0.0
	_draw_metal(rect, pressed)
	var c := rect.get_center() + (Vector2(1, 1) if pressed else Vector2.ZERO)
	var ink := Color("1a1a24")
	match button:
		"prev":
			draw_rect(Rect2(c + Vector2(-9, -6), Vector2(3, 12)), ink)
			draw_colored_polygon(PackedVector2Array([c + Vector2(6, -6), c + Vector2(-5, 0), c + Vector2(6, 6)]), ink)
		"play":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-5, -7), c + Vector2(7, 0), c + Vector2(-5, 7)]), ink)
		"pause":
			draw_rect(Rect2(c + Vector2(-6, -6), Vector2(4, 12)), ink)
			draw_rect(Rect2(c + Vector2(2, -6), Vector2(4, 12)), ink)
		"stop":
			draw_rect(Rect2(c - Vector2(6, 6), Vector2(12, 12)), ink)
		"next":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-6, -6), c + Vector2(5, 0), c + Vector2(-6, 6)]), ink)
			draw_rect(Rect2(c + Vector2(6, -6), Vector2(3, 12)), ink)


func _draw_logo() -> void:
	var x := _button_rect(BUTTONS.size() - 1).end.x + 20
	var y := window_rect.position.y + 150
	AppIcons.draw_bolt(self, Rect2(x, y, 22, 28))
	DrawUtil.text_left(self, "WhipAmp", Vector2(x + 28, y + 12), 20, GOLD, -1, 1, GOLD)
	var slogan := tr("WHIPAMP_SLOGAN")
	DrawUtil.text_left(self, slogan, Vector2(x, y + 44), DrawUtil.fit_size(slogan, 11, window_rect.end.x - x - 10), Color(GOLD, 0.75))


func _draw_inset(rect: Rect2, fill: Color) -> void:
	draw_rect(rect, fill)
	draw_line(rect.position, Vector2(rect.end.x, rect.position.y), EDGE_DARK, 1.5)
	draw_line(rect.position, Vector2(rect.position.x, rect.end.y), EDGE_DARK, 1.5)
	draw_line(rect.end, Vector2(rect.position.x, rect.end.y), EDGE_LIGHT, 1.0)
	draw_line(rect.end, Vector2(rect.end.x, rect.position.y), EDGE_LIGHT, 1.0)


## Brushed-metal button face.
func _draw_metal(rect: Rect2, pressed: bool) -> void:
	var top := Color("c8c8d4") if not pressed else Color("8a8a98")
	var bottom := Color("8a8a98") if not pressed else Color("b0b0bc")
	draw_polygon(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]),
			PackedColorArray([top, top, bottom, bottom]))
	draw_line(rect.position, Vector2(rect.end.x, rect.position.y), Color("ececf4") if not pressed else EDGE_DARK, 1.0)
	draw_line(rect.position, Vector2(rect.position.x, rect.end.y), Color("ececf4") if not pressed else EDGE_DARK, 1.0)
	draw_line(rect.end, Vector2(rect.position.x, rect.end.y), EDGE_DARK, 1.0)
	draw_line(rect.end, Vector2(rect.end.x, rect.position.y), EDGE_DARK, 1.0)
