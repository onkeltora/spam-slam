class_name DrawUtil
extends RefCounted
## Small helpers for text inside _draw(). Emojis come from the system font fallback.


static func font() -> Font:
	return ThemeDB.fallback_font


## Draws a single line centered on `center` (both axes).
static func text_centered(ci: CanvasItem, text: String, center: Vector2, size: int, color: Color,
		outline: int = 0, outline_color: Color = Color.BLACK) -> void:
	var f := font()
	var width := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var baseline := Vector2(center.x - width * 0.5, center.y + (f.get_ascent(size) - f.get_descent(size)) * 0.5)
	if outline > 0:
		ci.draw_string_outline(f, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, outline_color)
	ci.draw_string(f, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


## Draws a single line with its left edge at `left_center.x`, vertically centered.
static func text_left(ci: CanvasItem, text: String, left_center: Vector2, size: int, color: Color,
		max_width: float = -1.0, outline: int = 0, outline_color: Color = Color.BLACK) -> void:
	var f := font()
	var baseline := Vector2(left_center.x, left_center.y + (f.get_ascent(size) - f.get_descent(size)) * 0.5)
	if outline > 0:
		ci.draw_string_outline(f, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, max_width, size, outline, outline_color)
	ci.draw_string(f, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, max_width, size, color)


static func text_width(text: String, size: int) -> float:
	return font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## Largest font size <= `size` at which `text` fits into `max_width`.
static func fit_size(text: String, size: int, max_width: float, min_size: int = 10) -> int:
	var s := size
	while s > min_size and text_width(text, s) > max_width:
		s -= 1
	return s


static func rounded_rect(ci: CanvasItem, rect: Rect2, radius: float, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(int(radius))
	style.anti_aliasing = true
	ci.draw_style_box(style, rect)


static func rounded_frame(ci: CanvasItem, rect: Rect2, radius: float, color: Color, width: int) -> void:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = color
	style.set_border_width_all(width)
	style.set_corner_radius_all(int(radius))
	style.anti_aliasing = true
	ci.draw_style_box(style, rect)
