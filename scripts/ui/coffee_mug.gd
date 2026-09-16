extends Control
## Combo meter as a coffee mug: fills with each correct sort in a row.
## Full mug = caffeine boost, the mug then drains while steaming.

var _fill := 0.0
var _shown_fill := 0.0
var _boosting := false
var _time := 0.0
var _slosh := 0.0


func _ready() -> void:
	GameManager.coffee_changed.connect(func(f: float) -> void:
		if f < _fill - 0.2 and not _boosting:
			_slosh = 1.0
		_fill = f)
	GameManager.boost_started.connect(func(_d: float) -> void: _boosting = true)
	GameManager.boost_ended.connect(func() -> void: _boosting = false)
	GameManager.game_started.connect(func() -> void: _boosting = false)


func _process(delta: float) -> void:
	_time += delta
	_shown_fill = lerpf(_shown_fill, _fill, 1.0 - exp(-10.0 * delta))
	_slosh = move_toward(_slosh, 0.0, delta * 2.0)
	queue_redraw()


func _draw() -> void:
	var body := Rect2(8, 22, size.x - 34, size.y - 30)
	var wobble := sin(_time * 40.0) * 3.0 * _slosh
	draw_set_transform(Vector2(wobble, 0))

	# Handle
	draw_arc(Vector2(body.end.x, body.get_center().y), body.size.y * 0.26, -PI * 0.5, PI * 0.5, 16, Color("e9e4d8"), 7.0)
	draw_arc(Vector2(body.end.x, body.get_center().y), body.size.y * 0.26, -PI * 0.5, PI * 0.5, 16, Color("2a2420"), 2.0)
	# Mug body
	DrawUtil.rounded_rect(self, body, 6, Color("e9e4d8"))
	var inner := body.grow(-5)
	DrawUtil.rounded_rect(self, inner, 4, Color("3a3028"))
	# Coffee level
	var h := inner.size.y * _shown_fill
	if h > 1.0:
		var coffee_color := Color("c47a2c") if _boosting else Color("6b3f1d")
		var level := Rect2(inner.position.x, inner.end.y - h, inner.size.x, h)
		DrawUtil.rounded_rect(self, level, 4, coffee_color)
		draw_line(level.position, level.position + Vector2(level.size.x, 0), coffee_color.lightened(0.35), 2.0)
	DrawUtil.rounded_frame(self, body, 6, Color("2a2420"), 2)
	# DullCorp print on the mug
	DrawUtil.text_centered(self, "DC", body.get_center() + Vector2(0, -2), 16, Color(1, 1, 1, 0.55))

	# Steam while boosted (or when nearly full)
	if _boosting or _shown_fill > 0.8:
		var strength := 1.0 if _boosting else (_shown_fill - 0.8) * 5.0
		for i in 3:
			var x := body.position.x + body.size.x * (0.25 + i * 0.25)
			var pts := PackedVector2Array()
			for s in 8:
				var y := body.position.y - 2 - s * 3.0
				pts.append(Vector2(x + sin(_time * 5.0 + s * 0.8 + i * 2.0) * 3.0, y))
			draw_polyline(pts, Color(1, 1, 1, 0.45 * strength), 2.0, true)
	draw_set_transform(Vector2.ZERO)
