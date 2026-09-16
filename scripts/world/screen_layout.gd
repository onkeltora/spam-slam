class_name ScreenLayout
extends RefCounted
## Shared geometry of the desk scene (canvas 1280x720): the CRT monitor with its
## DullOS 98 desktop. Everything inside SCREEN_RECT gets the CRT shader.

const BEZEL_RECT := Rect2(168, 4, 944, 632)
const SCREEN_RECT := Rect2(200, 30, 880, 568)
const SCREEN_CORNER_RADIUS := 16.0
const TASKBAR_HEIGHT := 34.0
## Desktop area above the taskbar.
const DESKTOP_RECT := Rect2(200, 30, 880, 534)

const CARD_HOME := Vector2(640, 290)

## Folder icon centers per swipe direction (GameManager.Dir order: UP, DOWN, LEFT, RIGHT).
const FOLDER_SLOTS := [
	Vector2(640, 72),
	Vector2(640, 476),
	Vector2(272, 290),
	Vector2(1008, 290),
]

const DESKTOP_COLOR := Color("0f7f7f")
const WINDOW_GREY := Color("c9c6bb")
const BEVEL_LIGHT := Color("f4f2ea")
const BEVEL_DARK := Color("6d6a60")
const TITLE_BLUE := Color("1d2b73")
const TITLE_BLUE_END := Color("3d5bb8")
const TEXT_DARK := Color("1b1b1b")


static func taskbar_rect() -> Rect2:
	return Rect2(SCREEN_RECT.position.x, SCREEN_RECT.end.y - TASKBAR_HEIGHT, SCREEN_RECT.size.x, TASKBAR_HEIGHT)


## Raised 3D box in the classic 98 style.
static func draw_raised(ci: CanvasItem, rect: Rect2, fill: Color = WINDOW_GREY, width: float = 2.0) -> void:
	ci.draw_rect(rect, fill)
	ci.draw_line(rect.position, Vector2(rect.end.x, rect.position.y), BEVEL_LIGHT, width)
	ci.draw_line(rect.position, Vector2(rect.position.x, rect.end.y), BEVEL_LIGHT, width)
	ci.draw_line(rect.end, Vector2(rect.position.x, rect.end.y), BEVEL_DARK, width)
	ci.draw_line(rect.end, Vector2(rect.end.x, rect.position.y), BEVEL_DARK, width)


## Sunken 3D box (text fields, tray).
static func draw_sunken(ci: CanvasItem, rect: Rect2, fill: Color, width: float = 2.0) -> void:
	ci.draw_rect(rect, fill)
	ci.draw_line(rect.position, Vector2(rect.end.x, rect.position.y), BEVEL_DARK, width)
	ci.draw_line(rect.position, Vector2(rect.position.x, rect.end.y), BEVEL_DARK, width)
	ci.draw_line(rect.end, Vector2(rect.position.x, rect.end.y), BEVEL_LIGHT, width)
	ci.draw_line(rect.end, Vector2(rect.end.x, rect.position.y), BEVEL_LIGHT, width)


## Title bar with horizontal gradient.
static func draw_title_bar(ci: CanvasItem, rect: Rect2, c1: Color = TITLE_BLUE, c2: Color = TITLE_BLUE_END) -> void:
	ci.draw_polygon(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y),
			rect.end, Vector2(rect.position.x, rect.end.y)]), PackedColorArray([c1, c2, c2, c1]))


## The three minimize/maximize/close buttons at the right end of a title bar.
static func draw_window_buttons(ci: CanvasItem, title_rect: Rect2, button_size: Vector2 = Vector2(20, 18)) -> void:
	var right := title_rect.end.x - 4
	var cy := title_rect.get_center().y
	for i in 3:
		var r := Rect2(Vector2(right - (i + 1) * (button_size.x + 3), cy - button_size.y * 0.5), button_size)
		draw_raised(ci, r, WINDOW_GREY, 1.5)
		var c := r.get_center()
		var s := button_size.y * 0.28
		match i:
			0:
				ci.draw_line(c + Vector2(-s, -s), c + Vector2(s, s), TEXT_DARK, 2.0)
				ci.draw_line(c + Vector2(s, -s), c + Vector2(-s, s), TEXT_DARK, 2.0)
			1:
				ci.draw_rect(Rect2(c - Vector2(s, s * 0.8), Vector2(s * 2, s * 1.6)), TEXT_DARK, false, 1.5)
			2:
				ci.draw_line(c + Vector2(-s, s * 0.8), c + Vector2(s, s * 0.8), TEXT_DARK, 2.0)
