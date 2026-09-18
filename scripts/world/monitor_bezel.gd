extends Node2D
## Beige CRT monitor casing drawn on top of the screen area (and its CRT shader),
## so the rounded screen corners hide the shader's barrel distortion.
## The power LED turns amber when the inbox is critical and off when fired.

const CASE := Color("d6cfb9")
const CASE_LIGHT := Color("ece7d6")
const CASE_DARK := Color("9d967f")
const GLASS_EDGE := Color("1c1c1a")

## Shape comes from resources/screen_config.tres -- the CRT ColorRect/shader reads the
## same resource, so the picture and the hole cut for it can't drift apart.

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
	var cfg := ScreenLayout.config()
	var outer := ScreenLayout.BEZEL_RECT
	var screen := ScreenLayout.SCREEN_RECT

	# The tube face: the shape the picture actually has. The CRT ColorRect covers
	# SCREEN_RECT plus the bulge (see ScreenLayout.tube_rect()), so there is real
	# picture everywhere inside this outline -- the casing below cuts it to shape.
	var tube := _rounded_outline(screen, cfg.corner_radius, cfg.tube_bulge(), true)
	var casing := _rounded_outline(outer, cfg.casing_corner_radius if cfg.curved_casing else 0.0, cfg.casing_bulge_vec(), true)

	# Shadow on the desk, following the casing's own silhouette (a plain rect would poke
	# out through the rounded corners, where the casing no longer covers it).
	var shadow := PackedVector2Array()
	for i in casing.size() - 1:  # drop the duplicated closing point
		shadow.append(casing[i] + Vector2(10, 14))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.35))

	# Casing as one continuous ring between the two outlines. Quad per segment instead of
	# four slabs plus corner patches -- nothing to leave a seam or a hairline gap.
	_draw_ring(tube, casing)

	# Plastic highlights / shade on the outer edge
	var quarter := int((casing.size() - 1) / 4.0)
	draw_polyline(casing.slice(0, quarter + 1), CASE_LIGHT, 3.0)
	draw_polyline(casing.slice(quarter, quarter * 3 + 1), CASE_DARK, 4.0)
	draw_polyline(casing.slice(quarter * 3), CASE_LIGHT, 3.0)

	# Recessed glass edge, hugging the tube face
	draw_polyline(_rounded_outline(screen.grow(4.0), cfg.corner_radius + 4.0, cfg.tube_bulge(), true), CASE_DARK, 3.0)
	draw_polyline(tube, GLASS_EDGE, 4.0)

	# Brand badge + power LED + buttons on the chin
	# Measured from the tube's bottom, not the screen rect's -- the picture bulges past it.
	var chin_y := (screen.end.y + cfg.bulge_vertical + outer.end.y) * 0.5
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


## Point counts are fixed, never conditional: _draw_ring pairs the tube outline with the
## casing outline index by index, so both have to come out the same length even when one
## of them has no bulge or no corner radius at all.
const EDGE_STEPS := 12
const ARC_STEPS := 10


## A straight or bulged edge from `a` to `b` -- bows out along `out_dir` by `bulge` at
## its midpoint (0 = plain straight line, same as the old flat-edged look).
func _bulge_edge(a: Vector2, b: Vector2, out_dir: Vector2, bulge: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in EDGE_STEPS + 1:
		var t := float(i) / EDGE_STEPS
		pts.append(a.lerp(b, t) + out_dir * bulge * sin(t * PI))
	return pts


## Just the arc points around a rounded corner (no fill) -- for stroking an outline.
## Collapses onto the sharp `corner` when radius is 0, but keeps its point count.
func _corner_arc(corner: Vector2, inward: Vector2, radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	if radius <= 0.0:
		for i in ARC_STEPS + 1:
			pts.append(corner)
		return pts
	var center := corner + inward * radius
	var start_angle := atan2(-inward.y, 0.0)
	var end_angle := atan2(0.0, -inward.x)
	for i in ARC_STEPS + 1:
		var a := lerp_angle(start_angle, end_angle, float(i) / ARC_STEPS)
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	return pts


## Fills the casing as one continuous ring between two equally-sampled closed outlines.
func _draw_ring(inner: PackedVector2Array, outer: PackedVector2Array) -> void:
	for i in inner.size() - 1:
		draw_colored_polygon(PackedVector2Array([inner[i], inner[i + 1], outer[i + 1], outer[i]]), CASE)


## The full closed perimeter of a rounded, inward-bulged rect -- four (maybe bulged)
## edges plus four rounded corners, as one loop ready for draw_polyline. Used for the
## glass edge; radius=SCREEN_CORNER_RADIUS/bulge=0 reproduces the old plain frame.
##
## _corner_arc always runs from the horizontal edge to the vertical one, which is
## backwards for two of the four corners when walking the perimeter clockwise -- those
## two get reversed, otherwise the polyline cuts a diagonal across the corner and back.
## `bulge.x` bows the left/right edges, `bulge.y` the top/bottom ones.
func _rounded_outline(rect: Rect2, radius: float, bulge: Vector2, outward: bool = false) -> PackedVector2Array:
	var s := -1.0 if outward else 1.0
	var pts := PackedVector2Array()
	pts.append_array(_bulge_edge(Vector2(rect.position.x + radius, rect.position.y), Vector2(rect.end.x - radius, rect.position.y), Vector2(0, 1) * s, bulge.y))
	pts.append_array(_corner_arc(Vector2(rect.end.x, rect.position.y), Vector2(-1, 1), radius))
	pts.append_array(_bulge_edge(Vector2(rect.end.x, rect.position.y + radius), Vector2(rect.end.x, rect.end.y - radius), Vector2(-1, 0) * s, bulge.x))
	pts.append_array(_reversed(_corner_arc(rect.end, Vector2(-1, -1), radius)))
	pts.append_array(_bulge_edge(Vector2(rect.end.x - radius, rect.end.y), Vector2(rect.position.x + radius, rect.end.y), Vector2(0, -1) * s, bulge.y))
	pts.append_array(_corner_arc(Vector2(rect.position.x, rect.end.y), Vector2(1, -1), radius))
	pts.append_array(_bulge_edge(Vector2(rect.position.x, rect.end.y - radius), Vector2(rect.position.x, rect.position.y + radius), Vector2(1, 0) * s, bulge.x))
	pts.append_array(_reversed(_corner_arc(rect.position, Vector2(1, 1), radius)))
	pts.append(pts[0])  # close the loop
	return pts


func _reversed(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(pts.size() - 1, -1, -1):
		out.append(pts[i])
	return out

