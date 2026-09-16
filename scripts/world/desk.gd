extends Node2D
## The desk around the monitor: worn wood, monitor stand, keyboard edge, coffee rings
## and one of those free AOFF trial CDs that arrived with every magazine.

const SIZE := Vector2(1280, 720)
const CD_CENTER := Vector2(96, 318)
const CD_RADIUS := 60.0
const CD_ROTATION := -0.22

var boost := 0.0  # 0..1 warm tint during caffeine boost


func _ready() -> void:
	GameManager.language_changed.connect(queue_redraw)
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
	for i in 30:
		var y := -200.0 + i * 32.0
		draw_line(Vector2(-1000, y), Vector2(SIZE.x + 1000, y + 12.0), Color(0, 0, 0, 0.07), 2.0)

	# Coffee rings – the desk has seen things
	draw_arc(Vector2(84, 470), 34, 0.3, TAU - 0.6, 40, Color(0.25, 0.14, 0.06, 0.35), 5.0)
	draw_arc(Vector2(104, 458), 30, 1.5, TAU, 40, Color(0.25, 0.14, 0.06, 0.2), 4.0)
	draw_arc(Vector2(1190, 330), 26, 0.0, TAU - 1.2, 40, Color(0.25, 0.14, 0.06, 0.25), 4.0)

	_draw_aoff_cd()

	# Monitor stand
	var bezel := ScreenLayout.BEZEL_RECT
	var cx := bezel.get_center().x
	draw_rect(Rect2(cx - 150, bezel.end.y - 4, 300, 70), Color(0, 0, 0, 0.25))
	draw_rect(Rect2(cx - 70, bezel.end.y - 6, 140, 26), Color("bdb59c"))
	DrawUtil.rounded_rect(self, Rect2(cx - 160, bezel.end.y + 16, 320, 34), 10, Color("cfc8b0"))
	draw_line(Vector2(cx - 150, bezel.end.y + 18), Vector2(cx + 150, bezel.end.y + 18), Color("e6e0cc"), 2.0)

	# Keyboard edge peeking in at the bottom
	var kb := Rect2(cx - 330, 672, 660, 90)
	DrawUtil.rounded_rect(self, Rect2(kb.position + Vector2(6, -6), kb.size), 10, Color(0, 0, 0, 0.3))
	DrawUtil.rounded_rect(self, kb, 10, Color("d6cfb9"))
	for row in 2:
		for key in 15:
			var k := Rect2(kb.position.x + 14 + key * 42.5, kb.position.y + 10 + row * 34, 36, 28)
			DrawUtil.rounded_rect(self, k, 4, Color("ebe6d5"))
			draw_line(Vector2(k.position.x + 2, k.end.y), Vector2(k.end.x - 2, k.end.y), Color("a39c85"), 2.0)

	# Soft vignette towards the screen edges
	for i in 8:
		var inset := float(i) * 14.0
		var a := 0.05
		draw_rect(Rect2(-1000, -1000, SIZE.x + 2000, 1000 + 40 - inset), Color(0, 0, 0, a))
		draw_rect(Rect2(-1000, SIZE.y - 40 + inset, SIZE.x + 2000, 1000), Color(0, 0, 0, a))
		draw_rect(Rect2(-1000, -1000, 1000 + 60 - inset, SIZE.y + 2000), Color(0, 0, 0, a))
		draw_rect(Rect2(SIZE.x - 60 + inset, -1000, 1000, SIZE.y + 2000), Color(0, 0, 0, a))


func _draw_aoff_cd() -> void:
	var r := CD_RADIUS
	draw_circle(CD_CENTER + Vector2(5, 7), r, Color(0, 0, 0, 0.3))
	draw_set_transform(CD_CENTER, CD_ROTATION)

	# Printed disc with a bit of rainbow sheen at the rim
	draw_circle(Vector2.ZERO, r, Color("c8cdd4"))
	draw_circle(Vector2.ZERO, r - 3.0, Color("1d3f8f"))
	for i in 5:
		var hue := Color.from_hsv(0.1 + i * 0.17, 0.6, 1.0, 0.18)
		draw_arc(Vector2.ZERO, r - 1.5, -0.9 + i * 0.25, -0.6 + i * 0.25, 8, hue, 3.0)

	# Center hub and hole (the desk shows through)
	draw_circle(Vector2.ZERO, r * 0.3, Color("d9dde2"))
	draw_arc(Vector2.ZERO, r * 0.3, 0, TAU, 32, Color(0, 0, 0, 0.25), 1.5)
	draw_circle(Vector2.ZERO, r * 0.12, Color("5e4b36"))

	# Logo, product name and the famous offer
	AppIcons.draw_triangle_man(self, Vector2(-r * 0.45, -r * 0.52), r * 0.2)
	DrawUtil.text_left(self, "AOFF 5.0", Vector2(-r * 0.2, -r * 0.52), 14, Color.WHITE, -1, 1, Color.WHITE)
	var offer := tr("AOFF_CD_OFFER")
	DrawUtil.text_centered(self, offer, Vector2(0, r * 0.47), DrawUtil.fit_size(offer, 11, r * 1.2), Color("ffd23f"), 3, Color("0e2250"))
	draw_set_transform(Vector2.ZERO)
