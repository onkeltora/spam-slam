extends Node2D
## DullOS 98 desktop background inside the monitor screen, plus desktop icons in the
## top corners (not sorting targets, they sit below all windows). Single tap selects,
## double tap opens the program (handled by main.gd + AppWindows).

const LEFT_COLUMN_X := 274.0
const RIGHT_COLUMN_X := 1006.0
const FIRST_ROW_Y := 72.0
const ROW_SPACING := 84.0
const ICON_SIZE := 44.0
const FILE_PAGE_SIZE := Vector2(38, 46)
const LABEL_SIZE := 14
const ICONS := {
	"cat": Vector2(LEFT_COLUMN_X, FIRST_ROW_Y),
	"aoff": Vector2(LEFT_COLUMN_X, FIRST_ROW_Y + ROW_SPACING),
	"ocq": Vector2(RIGHT_COLUMN_X, FIRST_ROW_Y),
	"whipamp": Vector2(RIGHT_COLUMN_X, FIRST_ROW_Y + ROW_SPACING),
}
const SELECTION := Color("0a246a")

var selected := ""


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _ready() -> void:
	GameManager.language_changed.connect(queue_redraw)
	GameManager.game_started.connect(func() -> void: select(""))


## Icon id under a world position, or "".
func icon_at(world_pos: Vector2) -> String:
	for id in ICONS:
		if icon_rect(id).has_point(world_pos):
			return id
	return ""


## Clickable area of an icon (graphic + label).
func icon_rect(id: String) -> Rect2:
	var c: Vector2 = ICONS[id]
	return Rect2(c.x - 46, c.y - 28, 92, 76)


func select(id: String) -> void:
	selected = id
	queue_redraw()


func _draw() -> void:
	var screen := ScreenLayout.SCREEN_RECT
	draw_rect(screen, ScreenLayout.DESKTOP_COLOR)
	# Faint wallpaper logo behind everything
	var c := ScreenLayout.DESKTOP_RECT.get_center()
	DrawUtil.text_centered(self, "DullOS", c + Vector2(0, -8), 96, Color(1, 1, 1, 0.05))
	DrawUtil.text_centered(self, "98", c + Vector2(150, 50), 48, Color(1, 1, 1, 0.05))

	var cat: Vector2 = ICONS.cat
	_draw_image_file(cat)
	_draw_label(cat, tr("DESKTOP_FILE_CAT"), selected == "cat")

	var aoff: Vector2 = ICONS.aoff
	_draw_shortcut_backdrop(aoff)
	AppIcons.draw_triangle_man(self, aoff, ICON_SIZE * 0.42)
	_draw_shortcut_arrow(aoff)
	_draw_label(aoff, tr("DESKTOP_APP_ONLINE"), selected == "aoff")

	var ocq: Vector2 = ICONS.ocq
	_draw_shortcut_backdrop(ocq)
	AppIcons.draw_flower(self, ocq, ICON_SIZE * 0.46)
	_draw_shortcut_arrow(ocq)
	_draw_label(ocq, tr("DESKTOP_APP_CHAT"), selected == "ocq")

	var whipamp: Vector2 = ICONS.whipamp
	AppIcons.draw_bolt_tile(self, Rect2(whipamp - Vector2.ONE * ICON_SIZE * 0.45, Vector2.ONE * ICON_SIZE * 0.9))
	_draw_shortcut_arrow(whipamp)
	_draw_label(whipamp, tr("DESKTOP_APP_PLAYER"), selected == "whipamp")


## Soft drop shadow so round logos sit on the desktop like the square ones.
func _draw_shortcut_backdrop(center: Vector2) -> void:
	draw_circle(center + Vector2(3, 4), ICON_SIZE * 0.46, Color(0, 0, 0, 0.3))


## Little shortcut arrow in the bottom-left corner of a program icon.
func _draw_shortcut_arrow(center: Vector2) -> void:
	var box := Rect2(center + Vector2(-ICON_SIZE * 0.5, ICON_SIZE * 0.5 - 14), Vector2(14, 14))
	draw_rect(box, Color.WHITE)
	draw_rect(box, AppIcons.OUTLINE, false, 1.0)
	var o := box.position
	draw_line(o + Vector2(3, 11), o + Vector2(10, 4), AppIcons.OUTLINE, 2.0)
	draw_line(o + Vector2(6, 4), o + Vector2(10, 4), AppIcons.OUTLINE, 2.0)
	draw_line(o + Vector2(10, 4), o + Vector2(10, 8), AppIcons.OUTLINE, 2.0)


func _draw_label(center: Vector2, text: String, is_selected: bool) -> void:
	var pos := Vector2(center.x, center.y + FILE_PAGE_SIZE.y * 0.5 + 14)
	if is_selected:
		var w := DrawUtil.text_width(text, LABEL_SIZE)
		draw_rect(Rect2(pos.x - w * 0.5 - 4, pos.y - 10, w + 8, 20), SELECTION)
		draw_dashed_line(Vector2(pos.x - w * 0.5 - 4, pos.y + 10), Vector2(pos.x + w * 0.5 + 4, pos.y + 10), Color(1, 1, 1, 0.8), 1.0, 2.0)
	else:
		DrawUtil.text_centered(self, text, pos + Vector2(1, 1), LABEL_SIZE, Color(0, 0, 0, 0.75))
	DrawUtil.text_centered(self, text, pos, LABEL_SIZE, Color.WHITE)


## A .jpg file icon: page with folded corner and a thumbnail of... a cat. Obviously.
func _draw_image_file(center: Vector2) -> void:
	var page := Rect2(center - FILE_PAGE_SIZE * 0.5, FILE_PAGE_SIZE)
	var fold := 10.0
	var outline := AppIcons.OUTLINE
	var corner := Vector2(page.end.x, page.position.y)
	var shape := PackedVector2Array([
		page.position, corner - Vector2(fold, 0), corner + Vector2(0, fold),
		page.end, Vector2(page.position.x, page.end.y)])

	var shadow := shape.duplicate()
	for i in shadow.size():
		shadow[i] += Vector2(3, 4)
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.3))
	draw_colored_polygon(shape, Color("fbfaf4"))
	draw_colored_polygon(PackedVector2Array([corner - Vector2(fold, 0), corner + Vector2(0, fold),
			corner + Vector2(-fold, fold)]), Color("c9c6bb"))
	var closed := shape.duplicate()
	closed.append(shape[0])
	draw_polyline(closed, outline, 1.5)

	var thumb := Rect2(page.position + Vector2(5, 15), Vector2(FILE_PAGE_SIZE.x - 10, 24))
	draw_rect(thumb, Color("8fb4d8"))
	PixelIcons.draw_centered(self, PixelIcons.Icon.CAT, thumb.get_center() + Vector2(0, 1), 22)
	draw_rect(thumb, outline, false, 1.0)
