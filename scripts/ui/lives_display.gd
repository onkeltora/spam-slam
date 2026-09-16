extends Control
## Hearts in the top-right corner. Lost hearts stay as empty outlines.

const HEART_SIZE := 34.0
const SPACING := 40.0

var _lives := GameManager.START_LIVES
var _pop := 0.0
var _pop_index := -1
var _gained := false


func _ready() -> void:
	GameManager.lives_changed.connect(_on_lives_changed)


func _on_lives_changed(lives: int, delta: int) -> void:
	_pop_index = lives - 1 if delta > 0 else lives
	_gained = delta > 0
	_pop = 1.0 if delta != 0 else 0.0
	_lives = lives


func _process(delta: float) -> void:
	_pop = move_toward(_pop, 0.0, delta * 2.5)
	queue_redraw()


func _draw() -> void:
	var slots := maxi(GameManager.START_LIVES, _lives)
	for i in slots:
		# Right-aligned: slot 0 is the leftmost heart.
		var center := Vector2(size.x - HEART_SIZE * 0.5 - (slots - 1 - i) * SPACING, size.y * 0.5)
		var s := HEART_SIZE
		if i == _pop_index and _pop > 0.0:
			s *= 1.0 + sin(_pop * PI) * 0.5
			if not _gained:
				center += Vector2(randf_range(-3, 3), randf_range(-3, 3)) * _pop
		var filled := i < _lives
		_draw_heart(center, s, filled)


func _draw_heart(center: Vector2, s: float, filled: bool) -> void:
	var pts := PackedVector2Array()
	for step in 32:
		var t := TAU * step / 32.0
		# Classic parametric heart, normalized to ~1 unit
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
		pts.append(center + Vector2(x, y) * s / 34.0)
	var outline := pts.duplicate()
	outline.append(pts[0])
	if filled:
		draw_colored_polygon(pts, Color("e8394a"))
		draw_polyline(outline, Color("2a0a0e"), 3.0, true)
		draw_circle(center + Vector2(-s * 0.2, -s * 0.18), s * 0.09, Color(1, 1, 1, 0.7))
	else:
		draw_colored_polygon(pts, Color(0, 0, 0, 0.35))
		draw_polyline(outline, Color(0.6, 0.55, 0.5, 0.8), 2.5, true)
