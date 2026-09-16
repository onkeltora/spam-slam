class_name MailCard
extends Node2D
## The mail currently in front of the player: a 90s mail client window.
## Origin = card center. Follows the finger while dragging, then flies into a basket.

const WIDTH := 470.0
const TITLE_HEIGHT := 30.0
const PADDING := 14.0
const FIELD_GAP := 8.0
const FROM_SIZE := 19
const ADDRESS_SIZE := 15
const SUBJECT_SIZE := 25
const EXTRA_SIZE := 18
const EXTRA_LINE_HEIGHT := 25.0
const DRAG_SMOOTHING := 28.0

const COLOR_BODY := Color("c9c6bb")
const COLOR_BEVEL_LIGHT := Color("f4f2ea")
const COLOR_BEVEL_DARK := Color("6d6a60")
const COLOR_TITLE := Color("1d2b73")
const COLOR_TITLE_END := Color("3d5bb8")
const COLOR_FIELD := Color("fbfaf4")
const COLOR_TEXT := Color("1b1b1b")
const COLOR_LABEL := Color("55524a")
const COLOR_BOSS_TITLE := Color("b8860b")
const COLOR_BOSS_TITLE_END := Color("ffd65a")

var data: MailData
var card_size := Vector2(WIDTH, 200.0)
## Animated by the slide-in tween; drag offset is added on top.
var base_position := Vector2.ZERO
var flying := false

var _drag_target := Vector2.ZERO
var _drag := Vector2.ZERO
var _time := 0.0
var _subject_height := 0.0


func setup(mail: MailData, home: Vector2) -> void:
	data = mail
	base_position = home
	position = home
	_measure()
	queue_redraw()


func set_drag(offset: Vector2) -> void:
	_drag_target = offset


func _process(delta: float) -> void:
	_time += delta
	if flying:
		return
	_drag = _drag.lerp(_drag_target, 1.0 - exp(-DRAG_SMOOTHING * delta))
	position = base_position + _drag
	rotation = _drag.x * 0.0009
	if data != null and data.is_boss:
		queue_redraw()


## Tween into a basket, then free.
func fly_to(target: Vector2, duration: float = 0.17) -> void:
	flying = true
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position", target, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "scale", Vector2.ONE * 0.28, duration).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "rotation", rotation + randf_range(-0.5, 0.5), duration)
	tween.tween_property(self, "modulate:a", 0.0, duration).set_delay(duration * 0.6)
	tween.chain().tween_callback(queue_free)


## Game over: tumble off the desk.
func fall() -> void:
	flying = true
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position:y", position.y + 700.0, 0.9).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "rotation", randf_range(-1.2, 1.2), 0.9)
	tween.chain().tween_callback(queue_free)


func _measure() -> void:
	var content_width := WIDTH - PADDING * 4.0
	_subject_height = DrawUtil.font().get_multiline_string_size(
		data.get_subject(), HORIZONTAL_ALIGNMENT_LEFT, content_width, SUBJECT_SIZE, 2).y
	var extras := data.get_extra_lines().size()
	var height := TITLE_HEIGHT + PADDING
	height += 50.0 + FIELD_GAP                              # from field
	height += _subject_height + PADDING + FIELD_GAP          # subject field
	if extras > 0:
		height += extras * EXTRA_LINE_HEIGHT + FIELD_GAP
	height += PADDING - FIELD_GAP
	card_size = Vector2(WIDTH, height)


func _draw() -> void:
	if data == null:
		return
	var half := card_size * 0.5
	var rect := Rect2(-half, card_size)

	# Shadow + window body with 90s bevel
	draw_rect(Rect2(rect.position + Vector2(8, 10), rect.size), Color(0, 0, 0, 0.35))
	draw_rect(rect, COLOR_BODY)
	draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), COLOR_BEVEL_LIGHT, 3.0)
	draw_line(rect.position, rect.position + Vector2(0, rect.size.y), COLOR_BEVEL_LIGHT, 3.0)
	draw_line(rect.end, rect.end - Vector2(rect.size.x, 0), COLOR_BEVEL_DARK, 3.0)
	draw_line(rect.end, rect.end - Vector2(0, rect.size.y), COLOR_BEVEL_DARK, 3.0)

	# Title bar (gradient via two-tone polygon)
	var title_rect := Rect2(rect.position + Vector2(4, 4), Vector2(rect.size.x - 8, TITLE_HEIGHT - 4))
	var c1 := COLOR_BOSS_TITLE if data.is_boss else COLOR_TITLE
	var c2 := COLOR_BOSS_TITLE_END if data.is_boss else COLOR_TITLE_END
	draw_polygon(PackedVector2Array([title_rect.position, Vector2(title_rect.end.x, title_rect.position.y),
			title_rect.end, Vector2(title_rect.position.x, title_rect.end.y)]),
			PackedColorArray([c1, c2, c2, c1]))
	var title := tr("BOSS_WINDOW_TITLE") if data.is_boss else "✉ " + tr("MAIL_WINDOW_TITLE")
	DrawUtil.text_left(self, title, Vector2(title_rect.position.x + 8, title_rect.get_center().y), 15, Color.WHITE)
	_draw_window_buttons(title_rect)

	var x := rect.position.x + PADDING
	var inner_width := rect.size.x - PADDING * 2.0
	var y := rect.position.y + TITLE_HEIGHT + PADDING

	# From field
	var from_rect := Rect2(x, y, inner_width, 50.0)
	_draw_field(from_rect)
	var icon_center := Vector2(from_rect.position.x + 22, from_rect.get_center().y)
	DrawUtil.text_centered(self, data.get_icon(), icon_center, 24, Color.WHITE)
	var name_x := from_rect.position.x + 44
	DrawUtil.text_left(self, data.get_sender_name(), Vector2(name_x, from_rect.position.y + 16), FROM_SIZE,
			COLOR_TEXT, inner_width - 50, 1, COLOR_TEXT)
	DrawUtil.text_left(self, "<" + data.get_address() + ">", Vector2(name_x, from_rect.position.y + 36),
			ADDRESS_SIZE, COLOR_LABEL, inner_width - 50)
	y += from_rect.size.y + FIELD_GAP

	# Subject field – the main thing to read
	var subject_rect := Rect2(x, y, inner_width, _subject_height + PADDING)
	_draw_field(subject_rect)
	var f := DrawUtil.font()
	var subject_color := COLOR_LABEL if data.no_subject else COLOR_TEXT
	draw_multiline_string(f, Vector2(x + PADDING, y + PADDING * 0.5 + f.get_ascent(SUBJECT_SIZE)),
			data.get_subject(), HORIZONTAL_ALIGNMENT_LEFT, inner_width - PADDING * 2.0, SUBJECT_SIZE, 2, subject_color)
	y += subject_rect.size.y + FIELD_GAP

	# Attachments / links / amounts
	for line in data.get_extra_lines():
		DrawUtil.text_left(self, line, Vector2(x + 4, y + EXTRA_LINE_HEIGHT * 0.5), EXTRA_SIZE, COLOR_TEXT, inner_width)
		y += EXTRA_LINE_HEIGHT

	if data.is_boss:
		_draw_boss_shimmer(rect)


func _draw_field(rect: Rect2) -> void:
	draw_rect(rect, COLOR_FIELD)
	draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), COLOR_BEVEL_DARK, 2.0)
	draw_line(rect.position, rect.position + Vector2(0, rect.size.y), COLOR_BEVEL_DARK, 2.0)


func _draw_window_buttons(title_rect: Rect2) -> void:
	var size := Vector2(20, 18)
	var right := title_rect.end.x - 4
	var cy := title_rect.get_center().y
	for i in 3:
		var r := Rect2(Vector2(right - (i + 1) * (size.x + 3), cy - size.y * 0.5), size)
		draw_rect(r, COLOR_BODY)
		draw_line(r.position, Vector2(r.end.x, r.position.y), COLOR_BEVEL_LIGHT, 1.5)
		draw_line(r.end, Vector2(r.position.x, r.end.y), COLOR_BEVEL_DARK, 1.5)
		var c := r.get_center()
		match i:
			0:
				draw_line(c + Vector2(-5, -5), c + Vector2(5, 5), COLOR_TEXT, 2.0)
				draw_line(c + Vector2(5, -5), c + Vector2(-5, 5), COLOR_TEXT, 2.0)
			1:
				draw_rect(Rect2(c - Vector2(5, 4), Vector2(10, 8)), COLOR_TEXT, false, 1.5)
			2:
				draw_line(c + Vector2(-5, 4), c + Vector2(5, 4), COLOR_TEXT, 2.0)


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
