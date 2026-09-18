class_name PaperLetterCard
extends MailPresenter
## A handwritten-era paper letter (60er era). Drag/hit-test/fly-in physics live in the
## base class MailPresenter; this only measures and draws the letter sheet itself.
## No pixel-icon smileys here (MailGenerator never rolls them for PAPER medium) --
## the sender-kind icon and a cat mention (if any) are drawn as faded ink stamps.

## Real DIN-A4 page proportions (1:1.4142) -- a letter is a fixed sheet of paper,
## its size doesn't depend on how much was written on it. Short mails just leave
## the bottom of the page blank (with ruled lines across it), like a real letter.
const WIDTH := 320.0
const HEIGHT := WIDTH * 1.4142
const PADDING := 26.0
const HEADER_HEIGHT := 50.0
const RULE_GAP := 10.0
const BODY_SIZE := 25
const BODY_MAX_LINES := 5
const EXTRA_SIZE := 19
const EXTRA_LINE_HEIGHT := 28.0
const SENDER_SIZE := 19
const STAMP_SIZE := 50.0
const RULE_LINE_COUNT := 13

const COLOR_PAPER := Color("f2e6c9")
const COLOR_PAPER_EDGE := Color("cdbb8c")
const COLOR_INK := Color("2b2013")
const COLOR_INK_FADED := Color("7a6a48")
const COLOR_SEAL := Color("8a1f1f")
const COLOR_SEAL_DARK := Color("4f1010")
const COLOR_STAMP := Color("e6d9ab")

var _body_para: TextParagraph
var _body_lines := 1
var _body_text_height := 0.0


func _content_width() -> float:
	return WIDTH - PADDING * 2.0


func _measure() -> void:
	base_rotation = randf_range(-0.02, 0.02)
	var width := _content_width()
	_body_para = TextParagraph.new()
	_body_para.width = width
	_body_para.max_lines_visible = BODY_MAX_LINES
	_body_para.add_string(data.get_subject(), DrawUtil.font(), BODY_SIZE)
	_body_lines = mini(_body_para.get_line_count(), BODY_MAX_LINES)
	_body_text_height = 0.0
	for i in _body_lines:
		_body_text_height += _body_para.get_line_size(i).y

	card_size = Vector2(WIDTH, HEIGHT)


func _draw() -> void:
	if data == null:
		return
	var half := card_size * 0.5
	var rect := Rect2(-half, card_size)

	draw_rect(Rect2(rect.position + Vector2(7, 10), rect.size), Color(0, 0, 0, 0.3))
	draw_rect(rect, COLOR_PAPER)
	draw_rect(rect, COLOR_PAPER_EDGE, false, 2.0)
	for i in range(1, RULE_LINE_COUNT):
		var ly := rect.position.y + i * (rect.size.y / float(RULE_LINE_COUNT))
		draw_line(Vector2(rect.position.x + 10, ly), Vector2(rect.end.x - 10, ly), Color(COLOR_PAPER_EDGE, 0.35), 1.0)

	# Header: sender line + a faded ink stamp of the sender-kind icon
	var hx := rect.position.x + PADDING
	var hy := rect.position.y + PADDING * 0.7
	var stamp_center := Vector2(rect.end.x - PADDING - STAMP_SIZE * 0.5, rect.position.y + PADDING * 0.7 + STAMP_SIZE * 0.5)
	PixelIcons.draw_centered(self, data.get_icon(), Vector2(hx + 12, hy + 12), 24, COLOR_INK_FADED)
	var sender_text := tr("LETTER_FROM_PREFIX") + " " + data.get_sender_name()
	var sender_max_width := stamp_center.x - STAMP_SIZE * 0.5 - 10.0 - (hx + 30.0)
	var sender_size := DrawUtil.fit_size(sender_text, SENDER_SIZE, sender_max_width, 13)
	DrawUtil.text_left(self, sender_text, Vector2(hx + 30, hy + 12), sender_size, COLOR_INK)

	if data.is_boss:
		_draw_wax_seal(stamp_center)
	else:
		_draw_postage_stamp(stamp_center)

	var rule_y := rect.position.y + HEADER_HEIGHT
	draw_line(Vector2(rect.position.x + PADDING, rule_y), Vector2(rect.end.x - PADDING, rule_y), COLOR_INK_FADED, 1.5)

	# Body text -- the reason for writing
	var text_pos := Vector2(rect.position.x + PADDING, rule_y + RULE_GAP + PADDING * 0.3)
	_body_para.draw(get_canvas_item(), text_pos, COLOR_INK_FADED if data.no_subject else COLOR_INK)
	var y := text_pos.y + _body_text_height

	if data.has_cat:
		PixelIcons.draw_centered(self, PixelIcons.Icon.CAT, Vector2(text_pos.x + 12, y + 14), 22, COLOR_INK_FADED)
		DrawUtil.text_left(self, tr("LETTER_CAT_NOTE"), Vector2(text_pos.x + 26, y + 14), EXTRA_SIZE, COLOR_INK_FADED)
		y += 30.0

	for line in data.get_extra_lines():
		var cy := y + EXTRA_LINE_HEIGHT * 0.5
		DrawUtil.text_left(self, line.text, Vector2(text_pos.x, cy), EXTRA_SIZE, COLOR_INK)
		y += EXTRA_LINE_HEIGHT


## Red wax seal for a mail from the boss.
func _draw_wax_seal(center: Vector2) -> void:
	draw_circle(center + Vector2(2, 3), STAMP_SIZE * 0.5, Color(0, 0, 0, 0.25))
	draw_circle(center, STAMP_SIZE * 0.5, COLOR_SEAL)
	draw_arc(center, STAMP_SIZE * 0.5, 0.0, TAU, 24, COLOR_SEAL_DARK, 2.0)
	DrawUtil.text_centered(self, "S", center + Vector2(0, 1), 22, Color(1, 1, 1, 0.3))


## A plain period postage stamp with a perforated edge and a postmark smudge.
func _draw_postage_stamp(center: Vector2) -> void:
	var r := Rect2(center - Vector2.ONE * STAMP_SIZE * 0.5, Vector2.ONE * STAMP_SIZE)
	draw_rect(r, COLOR_STAMP)
	draw_rect(r, COLOR_INK_FADED, false, 1.5)
	var dot_gap := STAMP_SIZE / 6.0
	for i in 6:
		var t := (i + 0.5) * dot_gap
		draw_circle(Vector2(r.position.x + t, r.position.y), 1.5, COLOR_PAPER)
		draw_circle(Vector2(r.position.x + t, r.end.y), 1.5, COLOR_PAPER)
		draw_circle(Vector2(r.position.x, r.position.y + t), 1.5, COLOR_PAPER)
		draw_circle(Vector2(r.end.x, r.position.y + t), 1.5, COLOR_PAPER)
	draw_arc(center + Vector2(3, -2), STAMP_SIZE * 0.4, 0.0, TAU, 20, Color(COLOR_INK, 0.3), 1.5)
