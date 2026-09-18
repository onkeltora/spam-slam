class_name PaperTray
extends SortTarget
## A wooden in/out tray = one sorting target (60er era, no monitor/desktop icons).
## Slot position/preview/hit/miss animation state live in the base class SortTarget;
## this only draws the tray. Tinted by category, labeled on a little paper tag,
## with the base-rule legend below -- same information as SortFolder's desktop icon.

const TRAY_SIZE := Vector2(84, 44)
const LABEL_SIZE := 18
const LEGEND_SIZE := 14
const LEGEND_ICON := 15.0
const HIGHLIGHT := Color("6b3a1a")


func _draw() -> void:
	var color: Color = MailData.CATEGORY_COLORS[category]
	var offset := Vector2(sin(_time * 60.0) * 6.0 * _shake, 0.0)
	var blink_on := _correct_flash > 0.0 and fmod(_time * 8.0, 2.0) < 1.3
	var selected := _preview > 0.35 or _gulp > 0.0 or blink_on

	_draw_tray(offset, color, selected)

	var name_text := tr(MailData.CATEGORY_KEYS[category])
	var label_y := TRAY_SIZE.y * 0.5 + 22.0
	var name_w := DrawUtil.text_width(name_text, LABEL_SIZE)
	var label_rect := Rect2(offset.x - name_w * 0.5 - 6, label_y - 13, name_w + 12, 22)
	DrawUtil.rounded_rect(self, label_rect, 3.0, Color("f2e6c9").lerp(HIGHLIGHT, 0.55 if selected else 0.0))
	if blink_on:
		_draw_focus_frame(Rect2(offset - TRAY_SIZE * 0.5 - Vector2(8, 12), Vector2(TRAY_SIZE.x + 16, TRAY_SIZE.y + 66)))
	DrawUtil.text_centered(self, name_text, Vector2(offset.x, label_y), LABEL_SIZE, Color("2b2013"))

	var legend := tr(MailData.BASE_RULE_KEYS[category])
	var legend_w := DrawUtil.text_width(legend, LEGEND_SIZE) + LEGEND_ICON + 4.0
	var legend_left := offset.x - legend_w * 0.5
	var legend_y := label_y + 20.0
	PixelIcons.draw_centered(self, MailData.CATEGORY_ICONS[category], Vector2(legend_left + LEGEND_ICON * 0.5, legend_y), LEGEND_ICON, Color("6b5d44"))
	DrawUtil.text_left(self, legend, Vector2(legend_left + LEGEND_ICON + 4.0, legend_y), LEGEND_SIZE, Color("6b5d44"))


## A shallow wooden tray with a stack of paper inside, tinted by category.
func _draw_tray(offset: Vector2, color: Color, selected: bool) -> void:
	var s := TRAY_SIZE
	var body := Rect2(offset - s * 0.5, s)
	var wood := Color("8a5a34").lerp(HIGHLIGHT, 0.4 if selected else 0.0)
	var wood_dark := wood.darkened(0.3)
	if _shake > 0.0:
		wood = wood.lerp(Color(0.7, 0.15, 0.1), _shake * 0.6)

	draw_rect(Rect2(body.position + Vector2(3, 4), body.size), Color(0, 0, 0, 0.28))
	# Paper stack inside, tinted by category, tallest when a mail just landed
	var stack_h := s.y * 0.35 + sin(_gulp * PI) * 6.0
	var stack := Rect2(body.position + Vector2(6, s.y - 6 - stack_h), Vector2(s.x - 12, stack_h))
	draw_rect(stack, color.lightened(0.2))
	draw_rect(stack, color.darkened(0.2), false, 1.5)
	# Tray walls (front lower than back, like a real in-tray)
	var back := PackedVector2Array([body.position, Vector2(body.end.x, body.position.y), Vector2(body.end.x, body.position.y + 10), Vector2(body.position.x, body.position.y + 10)])
	draw_colored_polygon(back, wood_dark)
	var front_h := 14.0
	var front := PackedVector2Array([
		Vector2(body.position.x, body.end.y - front_h), Vector2(body.end.x, body.end.y - front_h),
		Vector2(body.end.x, body.end.y), Vector2(body.position.x, body.end.y)])
	draw_colored_polygon(front, wood)
	var side_l := PackedVector2Array([body.position, Vector2(body.position.x, body.end.y - front_h), Vector2(body.position.x + 4, body.end.y - front_h - 4), Vector2(body.position.x + 4, body.position.y + 4)])
	var side_r := PackedVector2Array([Vector2(body.end.x, body.position.y), Vector2(body.end.x, body.end.y - front_h), Vector2(body.end.x - 4, body.end.y - front_h - 4), Vector2(body.end.x - 4, body.position.y + 4)])
	draw_colored_polygon(side_l, wood)
	draw_colored_polygon(side_r, wood)
	var outline := Color("2b1a0d")
	draw_rect(body, outline, false, 2.0)
	draw_line(Vector2(body.position.x, body.end.y - front_h), Vector2(body.end.x, body.end.y - front_h), outline, 1.5)


## Classic dotted focus rectangle (same treatment as SortFolder's).
func _draw_focus_frame(rect: Rect2) -> void:
	var c := Color(0.15, 0.1, 0.05, minf(_correct_flash, 1.0))
	draw_dashed_line(rect.position, Vector2(rect.end.x, rect.position.y), c, 2.0, 3.0)
	draw_dashed_line(Vector2(rect.end.x, rect.position.y), rect.end, c, 2.0, 3.0)
	draw_dashed_line(rect.end, Vector2(rect.position.x, rect.end.y), c, 2.0, 3.0)
	draw_dashed_line(Vector2(rect.position.x, rect.end.y), rect.position, c, 2.0, 3.0)
