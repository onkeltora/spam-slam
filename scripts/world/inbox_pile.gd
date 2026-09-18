class_name InboxPile
extends Node2D
## The waiting mails behind the front card, as cascaded DullOS windows.
## Grows up-left, starts to lag and flicker when critical, and on overflow
## produces the classic "window trail" crash glitch before the bluescreen.
## Origin = front card center.

const LAYER_OFFSET := Vector2(-8, -7)
const LAYER_SIZE := Vector2(470, 190)
## Paper layers use PaperLetterCard's real DIN-A4 size (WIDTH/HEIGHT there) so the
## waiting stack of letters looks like a stack of actual pages, not little windows.
const LAYER_SIZE_PAPER := Vector2(320, 320 * 1.4142)
const BASE_TOP_MARGIN := -10.0  # how far a layer's center sits above the card center
const STRESS_START := 0.6      # pile ratio at which windows start to lag
const CRASH_TRAIL_INTERVAL := 0.025
const CRASH_TRAIL_MAX := 60

var _mails: Array = []
var _shift := 0.0              # eases layers back after the front card was taken
var _time := 0.0
var _crashing := false
var _trail: Array[Vector2] = []
var _trail_pos := Vector2.ZERO
var _trail_vel := Vector2.ZERO
var _trail_timer := 0.0


func set_mails(mails: Array) -> void:
	_mails = mails


## Called after the front mail was taken: remaining layers slide one step forward.
func advance() -> void:
	_shift = 1.0


func reset() -> void:
	_mails = []
	_trail.clear()
	_crashing = false
	_shift = 0.0


## Overflow: freeze the cascade and smear a window across the screen.
func crash() -> void:
	_crashing = true
	_trail.clear()
	_trail_pos = _layer_center(_mails.size())
	_trail_vel = Vector2([-1, 1].pick_random() * randf_range(700, 900), randf_range(500, 700))
	_trail_timer = 0.0


func _process(delta: float) -> void:
	_time += delta
	_shift = move_toward(_shift, 0.0, delta * 9.0)
	for mail in _mails:
		mail.pile_drop = move_toward(mail.pile_drop, 0.0, delta * 7.0)
	if _crashing:
		_update_trail(delta)
	queue_redraw()


func _update_trail(delta: float) -> void:
	if _trail.size() >= CRASH_TRAIL_MAX:
		return
	_trail_timer += delta
	while _trail_timer >= CRASH_TRAIL_INTERVAL and _trail.size() < CRASH_TRAIL_MAX:
		_trail_timer -= CRASH_TRAIL_INTERVAL
		_trail_pos += _trail_vel * CRASH_TRAIL_INTERVAL
		# Bounce inside the desktop (in local coordinates around the card home)
		var area := ScreenLayout.DESKTOP_RECT
		area.position -= global_position
		var half := _layer_size() * 0.5
		if _trail_pos.x - half.x < area.position.x or _trail_pos.x + half.x > area.end.x:
			_trail_vel.x *= -1.0
		if _trail_pos.y - half.y < area.position.y or _trail_pos.y + half.y > area.end.y:
			_trail_vel.y *= -1.0
		_trail.append(_trail_pos)


## True if a waiting window of the cascade covers this world position.
func covers(world_pos: Vector2) -> bool:
	var size := _layer_size()
	for i in _mails.size():
		var center := global_position + _layer_center(i + 1)
		if Rect2(center - size * 0.5, size).has_point(world_pos):
			return true
	return false


## Window layers (470x190) or paper layers (real DIN-A4 ratio), whichever the
## current era uses -- see PaperLetterCard.WIDTH/HEIGHT for where LAYER_SIZE_PAPER
## comes from.
func _layer_size() -> Vector2:
	return LAYER_SIZE if EraManager.current().has_monitor else LAYER_SIZE_PAPER


## BASE_TOP_MARGIN is how far a layer's center sits above the card center -- this
## cancels out regardless of layer size (a layer's own half-height already offsets
## it), so it works unchanged for both window and paper layers.
func _layer_center(layer: int) -> Vector2:
	return LAYER_OFFSET * (layer - _shift) + Vector2(0, BASE_TOP_MARGIN)


func _draw() -> void:
	var ratio := float(_mails.size() + 1) / GameManager.PILE_MAX
	var stress := clampf((ratio - STRESS_START) / (1.0 - STRESS_START), 0.0, 1.0)

	# Back to front: the oldest waiting mail is closest to the front card.
	for i in range(_mails.size() - 1, -1, -1):
		var mail: MailData = _mails[i]
		var center := _layer_center(i + 1) + mail.pile_jitter
		var lag := stress > 0.0 and randf() < stress * 0.35
		if lag and not _crashing:
			center.x += randf_range(-5.0, 5.0) * stress
		var pop := ease(mail.pile_drop, 2.0)
		draw_set_transform(center, 0.0, Vector2.ONE * (1.0 - pop * 0.15))
		if mail.medium == MailData.Medium.PAPER:
			_draw_paper_layer(1.0 - pop, lag or _crashing)
		else:
			_draw_window(1.0 - pop, lag or _crashing)
	draw_set_transform(Vector2.ZERO)

	var has_monitor: bool = EraManager.current().has_monitor
	for p in _trail:
		draw_set_transform(p)
		if has_monitor:
			_draw_window(1.0, true)
		else:
			_draw_paper_layer(1.0, true)
	draw_set_transform(Vector2.ZERO)


## A waiting mail: window frame + title bar. Grey title bar = "not responding".
func _draw_window(alpha: float, frozen: bool) -> void:
	if alpha <= 0.0:
		return
	var rect := Rect2(-LAYER_SIZE * 0.5, LAYER_SIZE)
	var body := Color(ScreenLayout.WINDOW_GREY, alpha)
	draw_rect(Rect2(rect.position + Vector2(5, 6), rect.size), Color(0, 0, 0, 0.22 * alpha))
	draw_rect(rect, body)
	draw_line(rect.position, Vector2(rect.end.x, rect.position.y), Color(ScreenLayout.BEVEL_LIGHT, alpha), 2.0)
	draw_line(rect.position, Vector2(rect.position.x, rect.end.y), Color(ScreenLayout.BEVEL_LIGHT, alpha), 2.0)
	draw_line(rect.end, Vector2(rect.end.x, rect.position.y), Color(ScreenLayout.BEVEL_DARK, alpha), 2.0)
	var title := Rect2(rect.position + Vector2(3, 3), Vector2(rect.size.x - 6, 18))
	if frozen:
		draw_rect(title, Color(0.5, 0.5, 0.5, alpha))
	else:
		ScreenLayout.draw_title_bar(self, title, Color(ScreenLayout.TITLE_BLUE, alpha), Color(ScreenLayout.TITLE_BLUE_END, alpha))


## A waiting paper letter: aged sheet, no title bar. A reddish tint stands in for
## "not responding" while under stress (there's no window chrome to grey out).
func _draw_paper_layer(alpha: float, distressed: bool) -> void:
	if alpha <= 0.0:
		return
	var rect := Rect2(-LAYER_SIZE_PAPER * 0.5, LAYER_SIZE_PAPER)
	draw_rect(Rect2(rect.position + Vector2(5, 6), rect.size), Color(0, 0, 0, 0.2 * alpha))
	draw_rect(rect, Color(Color("f2e6c9"), alpha))
	draw_rect(rect, Color(Color("cdbb8c"), alpha), false, 2.0)
	for i in range(1, 4):
		var ly := rect.position.y + i * (rect.size.y / 4.0)
		draw_line(Vector2(rect.position.x + 10, ly), Vector2(rect.end.x - 10, ly), Color(Color("cdbb8c"), alpha * 0.35), 1.0)
	if distressed:
		draw_rect(rect, Color(0.7, 0.15, 0.1, 0.28 * alpha))
