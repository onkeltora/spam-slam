class_name ScreenOverlay
extends Node2D
## Full-screen states of the monitor: bluescreen (inbox crash), CRT power-off
## (fired) and a short boot flash when a run starts. Inside the CRT area.

enum State { NONE, BOOT, BSOD, POWER_OFF }

const BOOT_TIME := 0.45
const POWER_OFF_TIME := 0.55
const BSOD_BLUE := Color("0000aa")

var _state := State.NONE
var _t := 0.0


func boot() -> void:
	_state = State.BOOT
	_t = 0.0


func bluescreen() -> void:
	_state = State.BSOD
	_t = 0.0


func power_off() -> void:
	_state = State.POWER_OFF
	_t = 0.0


func _process(delta: float) -> void:
	if _state == State.NONE:
		return
	_t += delta
	if _state == State.BOOT and _t > BOOT_TIME:
		_state = State.NONE
	queue_redraw()


func _draw() -> void:
	var screen := ScreenLayout.SCREEN_RECT
	var has_monitor: bool = EraManager.current().has_monitor
	match _state:
		State.BOOT:
			if not has_monitor:
				return  # no monitor to warm up
			# Picture fades in from black with a bright flash, like a CRT warming up
			var k := _t / BOOT_TIME
			draw_rect(screen, Color(0, 0, 0, 1.0 - ease(k, 0.5)))
			draw_rect(screen, Color(1, 1, 1, maxf(0.0, 0.35 - k) * 0.8))
		State.POWER_OFF:
			if has_monitor:
				_draw_power_off(screen)
			else:
				_draw_lights_out(screen)
		State.BSOD:
			if has_monitor:
				_draw_bluescreen(screen)
			else:
				_draw_paper_crash(screen)


func _draw_power_off(screen: Rect2) -> void:
	var k := clampf(_t / POWER_OFF_TIME, 0.0, 1.0)
	draw_rect(screen, Color.BLACK)
	var c := screen.get_center()
	if k < 0.55:
		# Picture collapses to a bright horizontal line...
		var h := lerpf(screen.size.y, 3.0, ease(k / 0.55, 2.2))
		draw_rect(Rect2(screen.position.x, c.y - h * 0.5, screen.size.x, h), Color(0.85, 0.95, 1.0, 1.0 - k))
	elif k < 1.0:
		# ...then to a fading dot
		var j := (k - 0.55) / 0.45
		var w := lerpf(screen.size.x, 4.0, ease(j, 2.5))
		draw_rect(Rect2(c.x - w * 0.5, c.y - 1.5, w, 3.0), Color(1, 1, 1, 1.0 - j * 0.5))
	else:
		var glow := maxf(0.0, 0.6 - (_t - POWER_OFF_TIME) * 0.8)
		draw_circle(c, 3.0, Color(1, 1, 1, glow))


## 60er equivalent of power_off(): no CRT to collapse, so the desk lamp just fades out.
func _draw_lights_out(screen: Rect2) -> void:
	var k := clampf(_t / POWER_OFF_TIME, 0.0, 1.0)
	draw_rect(screen, Color(0.05, 0.03, 0.0, ease(k, 1.5)))


## 60er equivalent of the bluescreen: the in-tray toppled, not a computer.
func _draw_paper_crash(screen: Rect2) -> void:
	draw_rect(screen, Color("cdbb8c"))
	var ink := Color("2b2013")
	var size := 20
	var x := screen.position.x + 60
	var y := screen.position.y + 150
	var width := screen.size.x - 120

	var title := " " + tr("PAPER_CRASH_TITLE") + " "
	var title_w := DrawUtil.text_width(title, size)
	var title_rect := Rect2(screen.get_center().x - title_w * 0.5 - 4, y - 16, title_w + 8, 30)
	draw_rect(title_rect, Color("8a1f1f"))
	DrawUtil.text_centered(self, title, title_rect.get_center(), size, Color.WHITE)
	y += 60

	for key in ["PAPER_CRASH_LINE_1", "PAPER_CRASH_LINE_2", "", "PAPER_CRASH_LINE_3", "PAPER_CRASH_LINE_4"]:
		if key != "":
			var line := tr(key)
			DrawUtil.text_left(self, line, Vector2(x, y), DrawUtil.fit_size(line, size, width), ink)
		y += 32
	y += 30
	var cont := tr("BSOD_CONTINUE")
	if fmod(_t, 1.0) > 0.5:
		cont = cont.trim_suffix("_")
	DrawUtil.text_centered(self, cont, Vector2(screen.get_center().x, y), size, ink)


func _draw_bluescreen(screen: Rect2) -> void:
	draw_rect(screen, BSOD_BLUE)
	var white := Color("f0f0f0")
	var size := 20
	var x := screen.position.x + 60
	var y := screen.position.y + 150
	var width := screen.size.x - 120

	var title := " " + tr("BSOD_TITLE") + " "
	var title_w := DrawUtil.text_width(title, size)
	var title_rect := Rect2(screen.get_center().x - title_w * 0.5 - 4, y - 16, title_w + 8, 30)
	draw_rect(title_rect, Color("aaaaaa"))
	DrawUtil.text_centered(self, title, title_rect.get_center(), size, BSOD_BLUE)
	y += 60

	for key in ["BSOD_LINE_1", "BSOD_LINE_2", "", "BSOD_LINE_3", "BSOD_LINE_4"]:
		if key != "":
			var line := tr(key)
			DrawUtil.text_left(self, line, Vector2(x, y), DrawUtil.fit_size(line, size, width), white)
		y += 32
	y += 30
	var cont := tr("BSOD_CONTINUE")
	if fmod(_t, 1.0) > 0.5:
		cont = cont.trim_suffix("_")
	DrawUtil.text_centered(self, cont, Vector2(screen.get_center().x, y), size, white)
