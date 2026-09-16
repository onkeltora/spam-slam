class_name AppIcons
extends RefCounted
## Vector logos of the parody apps living on the DullOS desktop around 2000:
## OCQ (messenger flower), WhipAmp (music player bolt), AOFF – America Offline (triangle man).
## Deliberately "inspired by", never the real logos.

const OUTLINE := Color("1a1a1a")


## OCQ flower: seven petals, one of them odd-colored. `lit` = 0..1 for the blinking tray version.
static func draw_flower(ci: CanvasItem, center: Vector2, radius: float, lit: float = 1.0) -> void:
	var petal_color := Color("e0453a").lerp(Color("7a3a36"), 1.0 - lit)
	var odd_color := Color("3fbf4a").lerp(Color("35603a"), 1.0 - lit)
	var petal_r := radius * 0.36
	for i in 7:
		var a := -PI * 0.5 + TAU * i / 7.0
		var p := center + Vector2(cos(a), sin(a)) * (radius - petal_r)
		ci.draw_circle(p, petal_r + 1.0, OUTLINE)
		ci.draw_circle(p, petal_r, odd_color if i == 2 else petal_color)
	ci.draw_circle(center, radius * 0.3 + 1.0, OUTLINE)
	ci.draw_circle(center, radius * 0.3, Color("ffd23f"))


## Small single-color flower used as online/away/offline status in the OCQ contact list.
static func draw_status_flower(ci: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	var petal_r := radius * 0.38
	for i in 7:
		var a := -PI * 0.5 + TAU * i / 7.0
		var p := center + Vector2(cos(a), sin(a)) * (radius - petal_r)
		ci.draw_circle(p, petal_r + 0.8, OUTLINE)
		ci.draw_circle(p, petal_r, color)
	ci.draw_circle(center, radius * 0.3, Color("ffd23f"))


## WhipAmp: lightning bolt in a dark rounded tile.
static func draw_bolt_tile(ci: CanvasItem, rect: Rect2) -> void:
	DrawUtil.rounded_rect(ci, rect, rect.size.x * 0.18, Color("2a2a36"))
	DrawUtil.rounded_frame(ci, rect, rect.size.x * 0.18, OUTLINE, 2)
	draw_bolt(ci, rect.grow(-rect.size.x * 0.16))


static func draw_bolt(ci: CanvasItem, rect: Rect2) -> void:
	var p := rect.position
	var s := rect.size
	var bolt := PackedVector2Array([
		p + Vector2(0.62, 0.0) * s, p + Vector2(0.18, 0.56) * s, p + Vector2(0.46, 0.56) * s,
		p + Vector2(0.34, 1.0) * s, p + Vector2(0.84, 0.38) * s, p + Vector2(0.56, 0.38) * s,
	])
	ci.draw_colored_polygon(bolt, Color("ffb020"))
	var closed := bolt.duplicate()
	closed.append(bolt[0])
	ci.draw_polyline(closed, OUTLINE, 1.5)


## AOFF: yellow triangle with a little running man, on a blue disc.
static func draw_triangle_man(ci: CanvasItem, center: Vector2, radius: float) -> void:
	ci.draw_circle(center, radius + 1.5, OUTLINE)
	ci.draw_circle(center, radius, Color("1d4fb0"))
	var r := radius * 0.72
	var tri := PackedVector2Array([center + Vector2(0, -r), center + Vector2(r * 0.9, r * 0.62), center + Vector2(-r * 0.9, r * 0.62)])
	ci.draw_colored_polygon(tri, Color("ffd23f"))
	var man := Color("1d4fb0")
	var w := maxf(radius * 0.09, 1.5)
	ci.draw_circle(center + Vector2(0, -r * 0.3), r * 0.13, man)
	ci.draw_line(center + Vector2(0, -r * 0.15), center + Vector2(0, r * 0.2), man, w)
	ci.draw_line(center + Vector2(0, r * 0.2), center + Vector2(-r * 0.25, r * 0.5), man, w)
	ci.draw_line(center + Vector2(0, r * 0.2), center + Vector2(r * 0.25, r * 0.5), man, w)
	ci.draw_line(center + Vector2(-r * 0.28, -r * 0.02), center + Vector2(r * 0.28, -r * 0.08), man, w)
