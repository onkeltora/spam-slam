extends Control
## Inbox counter bottom-left: one paper slot per mail, turns red and blinks
## before the pile collapses. Second fail condition, so it has to be loud.

var _count := 0
var _max := GameManager.PILE_MAX
var _time := 0.0
var _bump := 0.0


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

	var bg := Rect2(Vector2.ZERO, size)
	DrawUtil.rounded_rect(self, bg, 10, Color(0.05, 0.05, 0.06, 0.7))
	if danger:
		DrawUtil.rounded_frame(self, bg, 10, Color(1, 0.2, 0.15, 0.9 if blink else 0.4), 3)

	var label_color := Color("ff5a4a") if blink else Color(0.9, 0.88, 0.8)
	var count_text := "%d/%d" % [_count, _max]
	var count_size := int(26 * (1.0 + _bump * 0.25))
	var count_w := DrawUtil.text_width(count_text, 26)
	DrawUtil.text_left(self, count_text, Vector2(size.x - 14 - DrawUtil.text_width(count_text, count_size), 22),
			count_size, label_color, -1, 4, Color.BLACK)
	var label := "📥 " + tr("HUD_INBOX")
	DrawUtil.text_left(self, label, Vector2(14, 22), DrawUtil.fit_size(label, 18, size.x - 40 - count_w), label_color)

	# Slots
	var gap := 3.0
	var slot_w := (size.x - 28 - gap * (_max - 1)) / _max
	for i in _max:
		var r := Rect2(14 + i * (slot_w + gap), 44, slot_w, size.y - 58)
		var t := float(i) / (_max - 1)
		var color := Color("5fcf6a").lerp(Color("f2c14e"), clampf(t * 2.0, 0, 1)).lerp(Color("e8394a"), clampf(t * 2.0 - 1.0, 0, 1))
		if i < _count:
			draw_rect(r, color)
		else:
			draw_rect(r, Color(1, 1, 1, 0.08))
