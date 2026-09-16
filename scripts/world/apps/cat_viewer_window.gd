class_name CatViewerWindow
extends RetroWindow
## Image viewer for hairy_pussy.jpg. Shows the picture from the AppWindows inspector slot,
## or – until one is assigned – a procedurally drawn, absurdly fluffy cat.

const SIZE := Vector2(470, 420)
const STATUS_HEIGHT := 22.0
const FUR_STRANDS := 1500
const FUR_SEED := 1337

var picture: Texture2D

var _fur_points := PackedVector2Array()  # pairs of segment points in -1..1 cat space
var _fur_colors := PackedColorArray()


func _init() -> void:
	window_rect = Rect2(ScreenLayout.DESKTOP_RECT.get_center() - SIZE * 0.5 + Vector2(0, -6), SIZE)
	_build_fur()


func get_title() -> String:
	return tr("VIEWER_TITLE").format({"file": tr("DESKTOP_FILE_CAT")})


func draw_title_icon(center: Vector2) -> void:
	PixelIcons.draw_centered(self, PixelIcons.Icon.CAT, center, 16)


func draw_content(rect: Rect2) -> void:
	var picture_rect := Rect2(rect.position, rect.size - Vector2(0, STATUS_HEIGHT + 4))
	ScreenLayout.draw_sunken(self, picture_rect, Color("303030"))
	var inner := picture_rect.grow(-4)
	if picture != null:
		_draw_picture(inner)
	else:
		_draw_hairy_cat(inner)

	var status := Rect2(rect.position.x, rect.end.y - STATUS_HEIGHT, rect.size.x, STATUS_HEIGHT)
	ScreenLayout.draw_sunken(self, status, ScreenLayout.WINDOW_GREY, 1.5)
	DrawUtil.text_left(self, tr("VIEWER_STATUS"), Vector2(status.position.x + 8, status.get_center().y), 13, ScreenLayout.TEXT_DARK)


func _draw_picture(area: Rect2) -> void:
	var tex_size := picture.get_size()
	var s := minf(area.size.x / tex_size.x, area.size.y / tex_size.y)
	var size := tex_size * s
	draw_texture_rect(picture, Rect2(area.get_center() - size * 0.5, size), false)


# --- Procedural placeholder cat ---

func _build_fur() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = FUR_SEED
	var dark := Color("7a4a24")
	var mid := Color("c98a4b")
	var light := Color("f3dcb8")
	var strands: Array[Dictionary] = []
	for i in FUR_STRANDS:
		var on_head := rng.randf() < 0.42
		var center := Vector2(0, -0.28) if on_head else Vector2(0, 0.3)
		var radius := Vector2(0.46, 0.42) if on_head else Vector2(0.78, 0.55)
		var a := rng.randf() * TAU
		var depth := sqrt(rng.randf())  # more strands towards the outline
		var start := center + Vector2(cos(a) * radius.x, sin(a) * radius.y) * lerpf(0.2, 1.0, depth)
		var dir := Vector2(cos(a), sin(a)).rotated(rng.randf_range(-0.5, 0.5))
		var length := rng.randf_range(0.08, 0.2) if on_head else rng.randf_range(0.1, 0.32)
		var bend := dir.rotated(rng.randf_range(-0.9, 0.9))
		var mid_point := start + dir * length * 0.55
		var tip := mid_point + bend * length * 0.45
		var shade := rng.randf()
		var color := mid.lerp(light, shade) if rng.randf() < 0.7 else dark.lerp(mid, shade)
		strands.append({"depth": depth, "points": [start, mid_point, tip], "color": color})
	# Inner strands first, so the fluffy outline sits on top.
	strands.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return x.depth < y.depth)
	for strand in strands:
		var p: Array = strand.points
		_fur_points.append_array([p[0], p[1], p[1], p[2]])
		_fur_colors.append_array([strand.color, strand.color])


func _draw_hairy_cat(area: Rect2) -> void:
	draw_rect(area, Color("8fb4d8"))  # sky-blue "studio" backdrop
	var s := minf(area.size.x, area.size.y) * 0.4
	var origin := area.get_center() + Vector2(0, area.size.y * 0.06)
	draw_set_transform(origin, 0.0, Vector2.ONE * s)

	# Base fluff volume
	draw_circle(Vector2(0, 0.3), 0.62, Color("b07a44"))
	draw_circle(Vector2(0, -0.28), 0.42, Color("b07a44"))
	# Ears
	for side in [-1, 1]:
		draw_colored_polygon(PackedVector2Array([Vector2(0.18 * side, -0.62), Vector2(0.46 * side, -0.92),
				Vector2(0.44 * side, -0.46)]), Color("a06a38"))
		draw_colored_polygon(PackedVector2Array([Vector2(0.25 * side, -0.6), Vector2(0.43 * side, -0.82),
				Vector2(0.41 * side, -0.52)]), Color("e8a0a0"))

	draw_multiline_colors(_fur_points, _fur_colors, 1.6 / s)

	# Face peeking out of the fur
	for side in [-1, 1]:
		var eye := Vector2(0.17 * side, -0.3)
		draw_circle(eye, 0.085, Color("1a1a1a"))
		draw_circle(eye, 0.07, Color("c8d83a"))
		draw_colored_polygon(PackedVector2Array([eye + Vector2(0, -0.06), eye + Vector2(0.018, 0), eye + Vector2(0, 0.06),
				eye + Vector2(-0.018, 0)]), Color("1a1a1a"))
		draw_circle(eye + Vector2(-0.025, -0.025), 0.015, Color.WHITE)
	draw_colored_polygon(PackedVector2Array([Vector2(-0.04, -0.17), Vector2(0.04, -0.17), Vector2(0, -0.12)]), Color("e07a8a"))
	for side in [-1, 1]:
		for j in 3:
			var from := Vector2(0.06 * side, -0.13 + j * 0.025)
			draw_line(from, from + Vector2(0.42 * side, -0.05 + j * 0.05), Color(1, 1, 1, 0.75), 1.2 / s)
	draw_set_transform(Vector2.ZERO)
