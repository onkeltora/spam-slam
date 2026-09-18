class_name InTrayMeter
extends Node2D
## No-monitor eras' replacement for Taskbar's inbox button: the same fail-condition
## readout (GameManager.pile_changed), but as a small wooden sign standing on the desk
## instead of a taskbar widget -- there's no "not responding" window list to sit in.

const POSITION := Vector2(970, 655)  # clear of the typewriter and the webcam portrait
const SIZE := Vector2(250, 46)

var _count := 0
var _max := GameManager.PILE_MAX
var _time := 0.0
var _bump := 0.0


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	position = POSITION


func _ready() -> void:
	GameManager.pile_changed.connect(func(count: int, max_count: int) -> void:
		if count > _count:
			_bump = 1.0
		_count = count
		_max = max_count)
	GameManager.language_changed.connect(queue_redraw)


func _process(delta: float) -> void:
	_time += delta
	_bump = move_toward(_bump, 0.0, delta * 5.0)
	queue_redraw()


func _draw() -> void:
	var ratio := float(_count) / _max
	var danger := ratio >= 0.75
	var blink := danger and fmod(_time * (4.0 + ratio * 6.0), 1.0) < 0.5

	var rect := Rect2(-SIZE * 0.5, SIZE)
	draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.28))
	var wood := Color("e0303a") if blink else Color("8a5a34")
	draw_rect(rect, wood)
	draw_rect(rect, Color("2b1a0d"), false, 2.0)

	var text_color := Color.WHITE
	var label := "%s (%d)" % [tr("HUD_INBOX"), _count]
	var label_size := DrawUtil.fit_size(label, int(17 * (1.0 + _bump * 0.2)), rect.size.x - 110.0)
	DrawUtil.text_left(self, label, Vector2(rect.position.x + 10, rect.get_center().y - 8), label_size, text_color, -1, 1, Color(0, 0, 0, 0.5))

	# Fill slots -- same green -> amber -> red language as the taskbar's version
	var slots_width := 96.0
	var gap := 2.0
	var slot_w := (slots_width - gap * (_max - 1)) / _max
	var slots_x := rect.position.x + 10
	var slots_y := rect.get_center().y + 6
	for i in _max:
		var r := Rect2(slots_x + i * (slot_w + gap), slots_y, slot_w, 10)
		var t := float(i) / (_max - 1)
		var color := Color("3fae4a").lerp(Color("f2b12e"), clampf(t * 2.0, 0, 1)).lerp(Color("d8202a"), clampf(t * 2.0 - 1.0, 0, 1))
		draw_rect(r, color if i < _count else Color(0, 0, 0, 0.25))
		draw_rect(r, Color(0, 0, 0, 0.35), false, 1.0)
