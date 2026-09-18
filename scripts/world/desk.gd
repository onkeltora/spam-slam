extends Node2D
## The desk itself: worn wood, coffee rings, the Budget-Punkte-Shop decor once bought
## (MetaProgress) — the desk IS the meta-progress bar (GDD Abschnitt 9) — plus whatever
## era-specific hardware sits where the monitor would go (monitor stand + keyboard +
## AOFF CD for a has_monitor era, typewriter + rotary phone for the 60er).

const SIZE := Vector2(1280, 720)
const CD_CENTER := Vector2(96, 318)
const CD_RADIUS := 60.0
const CD_ROTATION := -0.22
const PLANT_CENTER := Vector2(1200, 530)
const LAMP_CENTER := Vector2(86, 450)  # between the AOFF CD/phone and the coffee-mug HUD widget
const PHONE_CENTER := Vector2(96, 330)
const TYPEWRITER_CENTER := Vector2(640, 700)

var boost := 0.0  # 0..1 warm tint during caffeine boost
var _plant_appear := 0.0  # 0..1, pops to 1 on purchase (see _on_item_purchased)
var _lamp_appear := 0.0


func _ready() -> void:
	GameManager.language_changed.connect(queue_redraw)
	GameManager.boost_started.connect(func(_d: float) -> void: _tween_boost(1.0))
	GameManager.boost_ended.connect(func() -> void: _tween_boost(0.0))
	GameManager.game_started.connect(func() -> void: _tween_boost(0.0))
	EraManager.era_changed.connect(func(_e: Dictionary) -> void: queue_redraw())
	_plant_appear = 1.0 if MetaProgress.is_owned("plant") else 0.0
	_lamp_appear = 1.0 if MetaProgress.is_owned("lamp") else 0.0
	MetaProgress.item_purchased.connect(_on_item_purchased)


func _tween_boost(target: float) -> void:
	create_tween().tween_method(func(v: float) -> void:
		boost = v
		queue_redraw(), boost, target, 0.4)


## The just-bought item pops onto the desk instead of silently appearing next run.
func _on_item_purchased(item_id: String) -> void:
	var setter: Callable
	match item_id:
		"plant":
			setter = func(v: float) -> void: _plant_appear = v
		"lamp":
			setter = func(v: float) -> void: _lamp_appear = v
		_:
			return
	create_tween().tween_method(func(v: float) -> void:
		setter.call(v)
		queue_redraw(), 0.0, 1.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


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

	var has_monitor: bool = EraManager.current().has_monitor
	if has_monitor:
		_draw_aoff_cd()
	else:
		_draw_phone()
	if _plant_appear > 0.0:
		_draw_plant()
	if _lamp_appear > 0.0:
		_draw_lamp()

	if has_monitor:
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
	else:
		_draw_typewriter()

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


## Shop item: a fanned-leaf potted plant, right of the monitor.
func _draw_plant() -> void:
	var s := ease(_plant_appear, 0.5)
	draw_set_transform(PLANT_CENTER, 0.0, Vector2.ONE * s)
	draw_circle(Vector2(0, 48), 28, Color(0, 0, 0, 0.22))

	var pot := PackedVector2Array([Vector2(-26, 0), Vector2(26, 0), Vector2(19, 46), Vector2(-19, 46)])
	draw_colored_polygon(pot, Color("b5652f"))
	var pot_outline := pot.duplicate()
	pot_outline.append(pot[0])
	draw_polyline(pot_outline, Color("6b3a1a"), 2.0)
	draw_rect(Rect2(-28, -7, 56, 9), Color("c97a3d"))
	draw_rect(Rect2(-28, -7, 56, 9), Color("6b3a1a"), false, 1.5)

	var leaf_count := 7
	for i in leaf_count:
		var t := float(i) / (leaf_count - 1)
		var angle := lerpf(-2.35, -0.8, t)  # fan from upper-left to upper-right
		var length := lerpf(58.0, 78.0, sin(t * PI))  # tallest in the middle
		var dir := Vector2(cos(angle), sin(angle))
		var tip := dir * length
		var side := dir.rotated(PI * 0.5) * 9.0
		var leaf := PackedVector2Array([Vector2.ZERO, tip * 0.5 + side, tip, tip * 0.5 - side])
		draw_colored_polygon(leaf, Color("2f8f3a").lightened(0.08 * (i % 3)))
		draw_line(Vector2.ZERO, tip, Color("1f6a28"), 1.5)
	draw_set_transform(Vector2.ZERO)


## Shop item: a classic green-shaded banker's lamp, left of the monitor.
func _draw_lamp() -> void:
	var s := ease(_lamp_appear, 0.5)
	draw_set_transform(LAMP_CENTER, 0.0, Vector2.ONE * s)
	draw_circle(Vector2(0, 58), 26, Color(0, 0, 0, 0.22))

	draw_colored_polygon(PackedVector2Array([Vector2(-30, 52), Vector2(30, 52), Vector2(22, 60), Vector2(-22, 60)]), Color("2a2a2a"))
	draw_rect(Rect2(-4, -30, 8, 82), Color("4a4a4a"))
	draw_circle(Vector2(0, -30), 6, Color("6a6a6a"))

	var shade := PackedVector2Array([Vector2(-34, -30), Vector2(34, -30), Vector2(20, -58), Vector2(-20, -58)])
	draw_colored_polygon(shade, Color("1f6a4a"))
	var shade_outline := shade.duplicate()
	shade_outline.append(shade[0])
	draw_polyline(shade_outline, Color("0f3a28"), 2.0)
	draw_rect(Rect2(-34, -32, 68, 5), Color("f2d98a"))

	draw_circle(Vector2(0, -20), 14, Color(1.0, 0.92, 0.6, 0.5))
	draw_circle(Vector2(0, -20), 7, Color(1.0, 0.95, 0.75, 0.9))
	draw_set_transform(Vector2.ZERO)


## 60er hardware: a black rotary phone, where the AOFF CD sits in later eras.
func _draw_phone() -> void:
	var c := PHONE_CENTER
	draw_circle(c + Vector2(4, 6), 62, Color(0, 0, 0, 0.3))

	# Base body
	var base := PackedVector2Array([
		c + Vector2(-58, 24), c + Vector2(58, 24), c + Vector2(46, -20), c + Vector2(-46, -20)])
	draw_colored_polygon(base, Color("1c1c1c"))
	var base_outline := base.duplicate()
	base_outline.append(base[0])
	draw_polyline(base_outline, Color("000000"), 2.0)

	# Rotary dial
	draw_circle(c + Vector2(0, 2), 30, Color("2a2a2a"))
	draw_circle(c + Vector2(0, 2), 30, Color("0a0a0a"), false, 2.0)
	draw_circle(c + Vector2(0, 2), 9, Color("3a3a3a"))
	for i in 10:
		var a := TAU * i / 10.0 - PI * 0.5
		var hole := c + Vector2(0, 2) + Vector2(cos(a), sin(a)) * 20.0
		draw_circle(hole, 3.2, Color("d8d0bc"))
		DrawUtil.text_centered(self, str((i + 1) % 10), hole, 8, Color("1a1a1a"))

	# Handset resting across the top, cord dangling to the base
	var cradle := c + Vector2(0, -32)
	draw_line(cradle, c + Vector2(-30, 10), Color("111111"), 3.0)
	var handset := Rect2(cradle - Vector2(46, 9), Vector2(92, 18))
	DrawUtil.rounded_rect(self, handset, 9, Color("242424"))
	draw_circle(handset.position + Vector2(10, 9), 9, Color("242424"))
	draw_circle(Vector2(handset.end.x - 10, handset.position.y + 9), 9, Color("242424"))


## 60er hardware: a portable typewriter, where the keyboard edge sits in later eras.
func _draw_typewriter() -> void:
	var c := TYPEWRITER_CENTER
	draw_rect(Rect2(c.x - 190, c.y - 6, 380, 60), Color(0, 0, 0, 0.28))

	# Case body
	DrawUtil.rounded_rect(self, Rect2(c.x - 190, c.y - 60, 380, 90), 14, Color("cfae5e"))
	DrawUtil.rounded_frame(self, Rect2(c.x - 190, c.y - 60, 380, 90), 14, Color("6b4f22"), 3)

	# Paper sticking up out of the carriage
	draw_rect(Rect2(c.x - 60, c.y - 128, 120, 76), Color("f4f0e2"))
	draw_rect(Rect2(c.x - 60, c.y - 128, 120, 76), Color("cdbb8c"), false, 1.5)
	for i in 3:
		draw_line(Vector2(c.x - 46, c.y - 108 + i * 12), Vector2(c.x + 30, c.y - 108 + i * 12), Color("cdbb8c", 0.5), 1.5)

	# Carriage roller bar
	draw_rect(Rect2(c.x - 170, c.y - 66, 340, 14), Color("3a3a3a"))
	draw_circle(Vector2(c.x - 170, c.y - 59), 9, Color("2a2a2a"))
	draw_circle(Vector2(c.x + 170, c.y - 59), 9, Color("2a2a2a"))

	# Two arced rows of round keys
	for row in 2:
		var key_count := 11 - row * 2
		var arc_w := 300.0 - row * 40.0
		for i in key_count:
			var t := float(i) / (key_count - 1)
			var x := c.x - arc_w * 0.5 + t * arc_w
			var y := c.y - 4 + row * 20.0 + sin(t * PI) * -6.0
			draw_circle(Vector2(x, y), 8.5, Color("2b2b2b"))
			draw_circle(Vector2(x, y), 6.0, Color("e8e2d0"))
