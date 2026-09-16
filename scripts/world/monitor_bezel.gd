extends Node2D
## Beige CRT monitor casing drawn on top of the screen area (and its CRT shader),
## so the rounded screen corners hide the shader's barrel distortion.
## The power LED turns amber when the inbox is critical and off when fired.

const CASE := Color("d6cfb9")
const CASE_LIGHT := Color("ece7d6")
const CASE_DARK := Color("9d967f")
const GLASS_EDGE := Color("1c1c1a")

var _pile_ratio := 0.0
var _powered := true
var _time := 0.0


func _ready() -> void:
	GameManager.pile_changed.connect(func(count: int, max_count: int) -> void: _pile_ratio = float(count) / max_count)
	GameManager.game_started.connect(func() -> void: _powered = true)
	GameManager.game_over.connect(func(reason: String) -> void: _powered = reason != "lives")


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var outer := ScreenLayout.BEZEL_RECT
	var screen := ScreenLayout.SCREEN_RECT
	var r := ScreenLayout.SCREEN_CORNER_RADIUS

	# Shadow on the desk
	DrawUtil.rounded_rect(self, Rect2(outer.position + Vector2(10, 14), outer.size), 22, Color(0, 0, 0, 0.35))

	# Casing ring: four slabs around the screen + rounded inner corners
	draw_rect(Rect2(outer.position, Vector2(outer.size.x, screen.position.y - outer.position.y)), CASE)
	draw_rect(Rect2(outer.position.x, screen.end.y, outer.size.x, outer.end.y - screen.end.y), CASE)
	draw_rect(Rect2(outer.position.x, screen.position.y, screen.position.x - outer.position.x, screen.size.y), CASE)
	draw_rect(Rect2(screen.end.x, screen.position.y, outer.end.x - screen.end.x, screen.size.y), CASE)
	_draw_corner(screen.position, Vector2(1, 1), r)
	_draw_corner(Vector2(screen.end.x, screen.position.y), Vector2(-1, 1), r)
	_draw_corner(screen.end, Vector2(-1, -1), r)
	_draw_corner(Vector2(screen.position.x, screen.end.y), Vector2(1, -1), r)

	# Plastic highlights / shade on the outer edge
	draw_line(outer.position, Vector2(outer.end.x, outer.position.y), CASE_LIGHT, 3.0)
	draw_line(outer.position, Vector2(outer.position.x, outer.end.y), CASE_LIGHT, 3.0)
	draw_line(outer.end, Vector2(outer.position.x, outer.end.y), CASE_DARK, 4.0)
	draw_line(outer.end, Vector2(outer.end.x, outer.position.y), CASE_DARK, 4.0)

	# Recessed glass edge
	DrawUtil.rounded_frame(self, screen.grow(4.0), r + 4.0, CASE_DARK, 3)
	DrawUtil.rounded_frame(self, screen, r, GLASS_EDGE, 4)

	# Brand badge + power LED + buttons on the chin
	var chin_y := (screen.end.y + outer.end.y) * 0.5
	DrawUtil.text_centered(self, "DullTron 17\"", Vector2(screen.get_center().x, chin_y), 14, CASE_DARK.darkened(0.2))
	var led := Vector2(screen.end.x - 30, chin_y)
	var led_color := Color("35d04a")
	if not _powered:
		led_color = Color("3a3a36")
	elif _pile_ratio >= 0.75 and fmod(_time * 6.0, 1.0) < 0.5:
		led_color = Color("ffb020")
	draw_circle(led, 4.0, led_color)
	if _powered:
		draw_circle(led, 8.0, Color(led_color, 0.25))
	for i in 2:
		DrawUtil.rounded_rect(self, Rect2(screen.end.x - 90 - i * 30, chin_y - 4, 20, 8), 3, CASE_DARK)


## Fills the square corner between the screen rect and its rounded edge.
func _draw_corner(corner: Vector2, inward: Vector2, radius: float) -> void:
	var center := corner + inward * radius
	var pts := PackedVector2Array([corner])
	var steps := 8
	var start_angle := atan2(-inward.y, 0.0)
	var end_angle := atan2(0.0, -inward.x)
	# Walk the arc from the vertical edge to the horizontal edge
	for i in steps + 1:
		var a := lerp_angle(start_angle, end_angle, float(i) / steps)
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	draw_colored_polygon(pts, CASE)
