class_name InboxPile
extends Node2D
## The physical stack of waiting mails behind the front card.
## Grows upwards, starts to sway when it gets critical and collapses on overflow.
## Origin = front card center.

const LAYER_OFFSET := 9.0
const LAYER_SIZE := Vector2(470, 190)
const BASE_TOP := -105.0
const DROP_HEIGHT := 170.0
const SWAY_START := 0.55       # pile ratio at which swaying begins

var _mails: Array = []
var _shift := 0.0              # eases layers down after the front card was taken
var _time := 0.0
var _collapsing := false
var _debris: Array[Dictionary] = []


func set_mails(mails: Array) -> void:
	_mails = mails


## Called after the front mail was taken: remaining layers slide down one step.
func advance() -> void:
	_shift = LAYER_OFFSET


func reset() -> void:
	_mails = []
	_debris.clear()
	_collapsing = false
	_shift = 0.0


func collapse() -> void:
	_collapsing = true
	_debris.clear()
	for i in _mails.size():
		var mail: MailData = _mails[i]
		_debris.append({
			"pos": _layer_center(i + 1, mail),
			"vel": Vector2(randf_range(-380, 380), randf_range(-520, -120)),
			"rot": mail.pile_rotation,
			"spin": randf_range(-6.0, 6.0),
		})
	_mails = []


func _process(delta: float) -> void:
	_time += delta
	_shift = move_toward(_shift, 0.0, delta * 80.0)
	for mail in _mails:
		mail.pile_drop = move_toward(mail.pile_drop, 0.0, delta * 5.0)
	for d in _debris:
		d.vel.y += 1500.0 * delta
		d.pos += d.vel * delta
		d.rot += d.spin * delta
	queue_redraw()


func _layer_center(layer: int, mail: MailData) -> Vector2:
	return Vector2(mail.pile_jitter.x, BASE_TOP - LAYER_OFFSET * layer + _shift + LAYER_SIZE.y * 0.5)


func _draw() -> void:
	if _collapsing:
		for d in _debris:
			draw_set_transform(d.pos, d.rot)
			_draw_layer(1.0)
		draw_set_transform(Vector2.ZERO)
		return

	var ratio := float(_mails.size() + 1) / GameManager.PILE_MAX
	var sway := 0.0
	if ratio > SWAY_START:
		var intensity := (ratio - SWAY_START) / (1.0 - SWAY_START)
		sway = sin(_time * lerpf(5.0, 13.0, intensity)) * intensity * 0.05

	# Draw back to front: topmost (newest) layer first.
	for i in range(_mails.size() - 1, -1, -1):
		var mail: MailData = _mails[i]
		var layer := i + 1
		var height_factor := float(layer) / GameManager.PILE_MAX
		var center := _layer_center(layer, mail)
		center.x += sway * 900.0 * height_factor * height_factor
		center.y -= ease(mail.pile_drop, 2.0) * DROP_HEIGHT
		var alpha := 1.0 - mail.pile_drop * 0.8
		draw_set_transform(center, mail.pile_rotation + sway * height_factor * 2.0)
		_draw_layer(alpha)
	draw_set_transform(Vector2.ZERO)


## A waiting mail seen from behind: just a window frame with a title bar.
func _draw_layer(alpha: float) -> void:
	var rect := Rect2(-LAYER_SIZE * 0.5, LAYER_SIZE)
	draw_rect(Rect2(rect.position + Vector2(5, 6), rect.size), Color(0, 0, 0, 0.25 * alpha))
	draw_rect(rect, Color(0.72, 0.70, 0.64, alpha))
	draw_rect(Rect2(rect.position + Vector2(3, 3), Vector2(rect.size.x - 6, 14)), Color(0.2, 0.26, 0.5, alpha))
	draw_rect(rect, Color(0.3, 0.29, 0.26, alpha), false, 2.0)
