extends Node2D
## Desk surface background: worn wood, a felt mat under the inbox, coffee rings.

const SIZE := Vector2(1280, 720)

var boost := 0.0  # 0..1 warm tint during caffeine boost


func _ready() -> void:
	GameManager.boost_started.connect(func(_d: float) -> void: _tween_boost(1.0))
	GameManager.boost_ended.connect(func() -> void: _tween_boost(0.0))
	GameManager.game_started.connect(func() -> void: _tween_boost(0.0))


func _tween_boost(target: float) -> void:
	create_tween().tween_method(func(v: float) -> void:
		boost = v
		queue_redraw(), boost, target, 0.4)


func _draw() -> void:
	# Oversized so the "expand" stretch aspect never shows the void.
	var wood := Color("5e4b36").lerp(Color("7a5230"), boost * 0.5)
	draw_rect(Rect2(-1000, -1000, SIZE.x + 2000, SIZE.y + 2000), wood)
	for i in 26:
		var y := -60.0 + i * 32.0
		draw_line(Vector2(-1000, y), Vector2(SIZE.x + 1000, y + 12.0), Color(0, 0, 0, 0.07), 2.0)

	var mat := Rect2(330, 170, 620, 440)
	DrawUtil.rounded_rect(self, Rect2(mat.position + Vector2(6, 8), mat.size), 18, Color(0, 0, 0, 0.3))
	DrawUtil.rounded_rect(self, mat, 18, Color("3f5246").lerp(Color("5a4a2f"), boost * 0.4))
	DrawUtil.rounded_frame(self, mat.grow(-10), 12, Color(1, 1, 1, 0.05), 2)

	# Coffee rings – the desk has seen things
	draw_arc(Vector2(270, 620), 34, 0.3, TAU - 0.6, 40, Color(0.25, 0.14, 0.06, 0.35), 5.0)
	draw_arc(Vector2(290, 608), 30, 1.5, TAU, 40, Color(0.25, 0.14, 0.06, 0.2), 4.0)
	draw_arc(Vector2(1010, 170), 26, 0.0, TAU - 1.2, 40, Color(0.25, 0.14, 0.06, 0.25), 4.0)

	# Soft vignette towards the screen edges
	for i in 8:
		var inset := float(i) * 14.0
		var a := 0.05
		draw_rect(Rect2(-1000, -1000, SIZE.x + 2000, 1000 + 40 - inset), Color(0, 0, 0, a))
		draw_rect(Rect2(-1000, SIZE.y - 40 + inset, SIZE.x + 2000, 1000), Color(0, 0, 0, a))
		draw_rect(Rect2(-1000, -1000, 1000 + 60 - inset, SIZE.y + 2000), Color(0, 0, 0, a))
		draw_rect(Rect2(SIZE.x - 60 + inset, -1000, 1000, SIZE.y + 2000), Color(0, 0, 0, a))
