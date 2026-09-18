class_name MailCard
extends MailPresenter
## A DullOS 98 mail window (90er era). Drag/hit-test/fly-in physics live in the base
## class MailPresenter; this only measures and draws the 98-chrome window itself.

const WIDTH := 470.0
const TITLE_HEIGHT := 30.0
const PADDING := 14.0
const FIELD_GAP := 8.0
const FROM_HEIGHT := 50.0
const FROM_SIZE := 19
const ADDRESS_SIZE := 15
const SUBJECT_SIZE := 25
const SUBJECT_MAX_LINES := 2
const SMILEY_SIZE := 24.0
const SMILEY_GAP := 3.0
const EXTRA_SIZE := 18
const EXTRA_LINE_HEIGHT := 25.0

const COLOR_FIELD := Color("fbfaf4")
const COLOR_LABEL := Color("55524a")
const COLOR_LINK := Color("1a33c8")
const COLOR_BOSS_TITLE := Color("b8860b")
const COLOR_BOSS_TITLE_END := Color("ffd65a")

var _subject_para: TextParagraph
var _subject_lines := 1
var _subject_text_height := 0.0
var _icons: Array[int] = []
var _icons_on_new_row := false
var _subject_height := 0.0


func _content_width() -> float:
	return WIDTH - PADDING * 4.0


func _measure() -> void:
	var width := _content_width()
	_subject_para = TextParagraph.new()
	_subject_para.width = width
	_subject_para.max_lines_visible = SUBJECT_MAX_LINES
	_subject_para.add_string(data.get_subject(), DrawUtil.font(), SUBJECT_SIZE)
	_subject_lines = mini(_subject_para.get_line_count(), SUBJECT_MAX_LINES)
	_subject_text_height = 0.0
	for i in _subject_lines:
		_subject_text_height += _subject_para.get_line_size(i).y

	# Smileys follow the text on its last line, or wrap into their own row.
	_icons = data.get_subject_icons()
	_icons_on_new_row = false
	if not _icons.is_empty():
		var icons_width := _icons.size() * (SMILEY_SIZE + SMILEY_GAP)
		_icons_on_new_row = _subject_para.get_line_width(_subject_lines - 1) + 8.0 + icons_width > width
	_subject_height = _subject_text_height + (SMILEY_SIZE + 4.0 if _icons_on_new_row else 0.0)

	var extras := data.get_extra_lines().size()
	var height := TITLE_HEIGHT + PADDING
	height += FROM_HEIGHT + FIELD_GAP
	height += _subject_height + PADDING + FIELD_GAP
	if extras > 0:
		height += extras * EXTRA_LINE_HEIGHT + FIELD_GAP
	height += PADDING - FIELD_GAP
	card_size = Vector2(WIDTH, height)


func _draw() -> void:
	if data == null:
		return
	var half := card_size * 0.5
	var rect := Rect2(-half, card_size)

	draw_rect(Rect2(rect.position + Vector2(8, 10), rect.size), Color(0, 0, 0, 0.35))
	ScreenLayout.draw_raised(self, rect, ScreenLayout.WINDOW_GREY, 3.0)

	# Title bar
	var title_rect := Rect2(rect.position + Vector2(4, 4), Vector2(rect.size.x - 8, TITLE_HEIGHT - 4))
	if data.is_boss:
		ScreenLayout.draw_title_bar(self, title_rect, COLOR_BOSS_TITLE, COLOR_BOSS_TITLE_END)
		DrawUtil.text_left(self, tr("BOSS_WINDOW_TITLE"), Vector2(title_rect.position.x + 8, title_rect.get_center().y), 15, Color.WHITE)
	else:
		ScreenLayout.draw_title_bar(self, title_rect)
		PixelIcons.draw_centered(self, PixelIcons.Icon.ENVELOPE, Vector2(title_rect.position.x + 14, title_rect.get_center().y), 18)
		DrawUtil.text_left(self, tr("MAIL_WINDOW_TITLE"), Vector2(title_rect.position.x + 28, title_rect.get_center().y), 15, Color.WHITE)
	ScreenLayout.draw_window_buttons(self, title_rect)

	var x := rect.position.x + PADDING
	var inner_width := rect.size.x - PADDING * 2.0
	var y := rect.position.y + TITLE_HEIGHT + PADDING

	# From field
	var from_rect := Rect2(x, y, inner_width, FROM_HEIGHT)
	ScreenLayout.draw_sunken(self, from_rect, COLOR_FIELD)
	PixelIcons.draw_centered(self, data.get_icon(), Vector2(from_rect.position.x + 22, from_rect.get_center().y), 24)
	var name_x := from_rect.position.x + 44
	DrawUtil.text_left(self, data.get_sender_name(), Vector2(name_x, from_rect.position.y + 16), FROM_SIZE,
			ScreenLayout.TEXT_DARK, inner_width - 50, 1, ScreenLayout.TEXT_DARK)
	DrawUtil.text_left(self, "<" + data.get_address() + ">", Vector2(name_x, from_rect.position.y + 36),
			ADDRESS_SIZE, COLOR_LABEL, inner_width - 50)
	y += from_rect.size.y + FIELD_GAP

	# Subject field – the main thing to read
	var subject_rect := Rect2(x, y, inner_width, _subject_height + PADDING)
	ScreenLayout.draw_sunken(self, subject_rect, COLOR_FIELD)
	var text_pos := Vector2(x + PADDING, y + PADDING * 0.5)
	_subject_para.draw(get_canvas_item(), text_pos, COLOR_LABEL if data.no_subject else ScreenLayout.TEXT_DARK)
	if not _icons.is_empty():
		var icon_x: float
		var icon_cy: float
		if _icons_on_new_row:
			icon_x = text_pos.x
			icon_cy = text_pos.y + _subject_text_height + 2.0 + SMILEY_SIZE * 0.5
		else:
			var last := _subject_lines - 1
			var last_top := text_pos.y + _subject_text_height - _subject_para.get_line_size(last).y
			icon_x = text_pos.x + _subject_para.get_line_width(last) + 8.0
			icon_cy = last_top + _subject_para.get_line_size(last).y * 0.5
		for i in _icons.size():
			PixelIcons.draw_centered(self, _icons[i], Vector2(icon_x + SMILEY_SIZE * 0.5 + i * (SMILEY_SIZE + SMILEY_GAP), icon_cy), SMILEY_SIZE)
	y += subject_rect.size.y + FIELD_GAP

	# Attachments / links / amounts
	for line in data.get_extra_lines():
		var cy := y + EXTRA_LINE_HEIGHT * 0.5
		var tx := x + 4
		if line.icon >= 0:
			PixelIcons.draw_centered(self, line.icon, Vector2(tx + 9, cy), 18)
			tx += 24
		var color := COLOR_LINK if line.link else ScreenLayout.TEXT_DARK
		var text_size := DrawUtil.fit_size(line.text, EXTRA_SIZE, inner_width - (tx - x) - 4)
		DrawUtil.text_left(self, line.text, Vector2(tx, cy), text_size, color)
		if line.link:
			var w := DrawUtil.text_width(line.text, text_size)
			draw_line(Vector2(tx, cy + text_size * 0.55), Vector2(tx + w, cy + text_size * 0.55), COLOR_LINK, 1.5)
		y += EXTRA_LINE_HEIGHT

	if data.is_boss:
		_draw_boss_shimmer(rect)


## Diagonal golden glint sweeping over the boss mail.
func _draw_boss_shimmer(rect: Rect2) -> void:
	var sweep := fmod(_time * 0.8, 1.6) - 0.3
	var cx := rect.position.x + rect.size.x * sweep
	var w := 60.0
	var pts := PackedVector2Array([
		Vector2(cx - w, rect.end.y), Vector2(cx, rect.end.y),
		Vector2(cx + 80, rect.position.y), Vector2(cx + 80 - w, rect.position.y)])
	var clipped := Geometry2D.intersect_polygons(pts, PackedVector2Array([
		rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]))
	for poly in clipped:
		draw_colored_polygon(poly, Color(1.0, 0.9, 0.4, 0.22))
	draw_rect(rect.grow(3.0), Color(1.0, 0.8, 0.2, 0.6 + 0.4 * sin(_time * 6.0)), false, 3.0)
