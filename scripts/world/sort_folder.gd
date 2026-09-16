class_name SortFolder
extends Node2D
## A desktop folder icon = one sorting target. Origin = folder icon center.
## Tinted by category, labeled like a desktop icon, with the base-rule legend below.
## Reacts to drag preview (selection highlight), hits (flap opens) and misses.

const ICON_SIZE := Vector2(66, 50)
const LABEL_SIZE := 19
const LEGEND_SIZE := 15
const LEGEND_ICON := 16.0
const HIGHLIGHT := Color("0a246a")

var category: MailData.Category
var dir: GameManager.Dir

var _preview := 0.0        # 0..1 while the player drags towards this folder
var _gulp := 0.0           # flap opens after a correct hit
var _shake := 0.0          # wiggle after a wrong hit
var _correct_flash := 0.0  # blinking focus frame: "this would have been right"
var _time := 0.0


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func setup(p_category: MailData.Category, p_dir: GameManager.Dir) -> void:
	category = p_category
	dir = p_dir
	position = ScreenLayout.FOLDER_SLOTS[dir]
	GameManager.language_changed.connect(queue_redraw)
	queue_redraw()


func move_to_slot(new_dir: GameManager.Dir) -> void:
	if new_dir == dir:
		return
	dir = new_dir
	create_tween().tween_property(self, "position", ScreenLayout.FOLDER_SLOTS[dir], 0.55) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	_correct_flash = 1.6


func set_preview(amount: float) -> void:
	_preview = amount


func gulp() -> void:
	_gulp = 1.0


func reject() -> void:
	_shake = 1.0


func flash_correct() -> void:
	_correct_flash = 1.1


func _process(delta: float) -> void:
	_time += delta
	_gulp = move_toward(_gulp, 0.0, delta * 3.0)
	_shake = move_toward(_shake, 0.0, delta * 2.5)
	_correct_flash = move_toward(_correct_flash, 0.0, delta)
	scale = Vector2.ONE * (1.0 + sin(_gulp * PI) * 0.18 + _preview * 0.1)
	queue_redraw()


func _draw() -> void:
	var color: Color = MailData.CATEGORY_COLORS[category]
	var offset := Vector2(sin(_time * 60.0) * 7.0 * _shake, 0.0)
	var blink_on := _correct_flash > 0.0 and fmod(_time * 8.0, 2.0) < 1.3
	var selected := _preview > 0.35 or _gulp > 0.0 or blink_on

	_draw_folder(offset, color, selected)

	# Label: white text on the desktop, navy highlight when selected (like a real icon)
	var name_text := tr(MailData.CATEGORY_KEYS[category])
	var label_y := ICON_SIZE.y * 0.5 + 16.0
	var name_w := DrawUtil.text_width(name_text, LABEL_SIZE)
	var label_rect := Rect2(offset.x - name_w * 0.5 - 5, label_y - 12, name_w + 10, 24)
	if selected:
		draw_rect(label_rect, HIGHLIGHT)
	if blink_on:
		_draw_focus_frame(Rect2(offset - ICON_SIZE * 0.5 - Vector2(8, 10), Vector2(ICON_SIZE.x + 16, ICON_SIZE.y + 58)))
	var shadow := Color(0, 0, 0, 0.0) if selected else Color(0, 0, 0, 0.75)
	DrawUtil.text_centered(self, name_text, Vector2(offset.x + 1, label_y + 1), LABEL_SIZE, shadow)
	DrawUtil.text_centered(self, name_text, Vector2(offset.x, label_y), LABEL_SIZE, Color.WHITE)

	# Base-rule legend: pixel icon + text
	var legend := tr(MailData.BASE_RULE_KEYS[category])
	var legend_w := DrawUtil.text_width(legend, LEGEND_SIZE) + LEGEND_ICON + 4.0
	var legend_left := offset.x - legend_w * 0.5
	var legend_y := label_y + 21.0
	draw_rect(Rect2(legend_left - 4, legend_y - 10, legend_w + 8, 20), Color(0, 0, 0, 0.28))
	PixelIcons.draw_centered(self, MailData.CATEGORY_ICONS[category], Vector2(legend_left + LEGEND_ICON * 0.5, legend_y), LEGEND_ICON)
	DrawUtil.text_left(self, legend, Vector2(legend_left + LEGEND_ICON + 4.0, legend_y), LEGEND_SIZE, Color(1, 1, 1, 0.92))


func _draw_folder(offset: Vector2, color: Color, selected: bool) -> void:
	var s := ICON_SIZE
	var body := Rect2(offset - s * 0.5 + Vector2(0, 6), Vector2(s.x, s.y - 6))
	var outline := Color("1a1a1a")
	var back := color.darkened(0.25)
	var front := color.lightened(0.15)
	if selected:
		back = back.lerp(HIGHLIGHT, 0.45)
		front = front.lerp(HIGHLIGHT, 0.45)
	if _shake > 0.0:
		front = front.lerp(Color(1, 0.2, 0.15), _shake * 0.6)

	draw_rect(Rect2(body.position + Vector2(4, 5), body.size), Color(0, 0, 0, 0.3))
	# Back plate with tab
	var tab := PackedVector2Array([
		body.position, body.position + Vector2(0, -7), body.position + Vector2(24, -7),
		body.position + Vector2(30, 0)])
	draw_colored_polygon(tab, back)
	draw_rect(body, back)
	# Paper sticking out
	draw_rect(Rect2(body.position + Vector2(6, 4), Vector2(body.size.x - 12, body.size.y - 10)), Color("f4f2ea"))
	# Front flap: tilts open when a mail lands
	var open := sin(_gulp * PI) * 16.0
	var flap := PackedVector2Array([
		body.position + Vector2(0, 12), body.position + Vector2(body.size.x, 12),
		body.end, Vector2(body.position.x, body.end.y)])
	flap[0].x -= open * 0.6
	flap[1].x += open * 0.6
	flap[0].y += open
	flap[1].y += open
	draw_colored_polygon(flap, front)
	var flap_outline := flap.duplicate()
	flap_outline.append(flap[0])
	draw_polyline(flap_outline, outline, 2.0)
	draw_rect(body, outline, false, 2.0)
	draw_polyline(PackedVector2Array([tab[0], tab[1], tab[2], tab[3]]), outline, 2.0)


## Classic dotted focus rectangle.
func _draw_focus_frame(rect: Rect2) -> void:
	var c := Color(1, 1, 1, minf(_correct_flash, 1.0))
	draw_dashed_line(rect.position, Vector2(rect.end.x, rect.position.y), c, 2.0, 3.0)
	draw_dashed_line(Vector2(rect.end.x, rect.position.y), rect.end, c, 2.0, 3.0)
	draw_dashed_line(rect.end, Vector2(rect.position.x, rect.end.y), c, 2.0, 3.0)
	draw_dashed_line(Vector2(rect.position.x, rect.end.y), rect.position, c, 2.0, 3.0)
