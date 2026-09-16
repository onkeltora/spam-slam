extends Node2D
## DullOS message box that pops up for NEW RULE!, REORG! and CAFFEINE BOOST!
## Lives inside the screen (gets the CRT look). Timing matches the spawn pause.

enum Kind { WARNING, INFO }

const POP_TIME := 0.14
const HOLD_TIME := 1.05
const CLOSE_TIME := 0.14
const MIN_WIDTH := 420.0
const MAX_WIDTH := 700.0
const HEIGHT := 176.0
const TITLE_SIZE := 30
const MESSAGE_SIZE := 21

var _title := ""
var _message := ""
var _accent := Color.WHITE
var _kind := Kind.WARNING
var _t := -1.0


func _ready() -> void:
	GameManager.rule_changed.connect(func(rule: SortRule) -> void:
		if rule != null:
			show_message(tr("HUD_NEW_RULE"), rule.get_text(), MailData.CATEGORY_COLORS[rule.target], Kind.WARNING)
			GameManager.screen_shake.emit(6.0))
	GameManager.baskets_swapped.connect(func(_a: int, _b: int) -> void:
		show_message(tr("HUD_REORG_TITLE"), tr("HUD_REORG_TEXT"), Color("ff8a3d"), Kind.WARNING))
	GameManager.boost_started.connect(func(_d: float) -> void:
		show_message(tr("HUD_BOOST"), tr("HUD_BOOST_TEXT"), Color("c47a2c"), Kind.INFO))
	GameManager.game_started.connect(func() -> void: _t = -1.0)
	GameManager.game_over.connect(func(_r: String) -> void: _t = -1.0)


func show_message(title: String, message: String, accent: Color, kind: Kind) -> void:
	_title = title
	_message = message
	_accent = accent
	_kind = kind
	_t = 0.0


func _process(delta: float) -> void:
	if _t < 0.0:
		return
	_t += delta
	if _t > POP_TIME + HOLD_TIME + CLOSE_TIME:
		_t = -1.0
	queue_redraw()


func _draw() -> void:
	if _t < 0.0:
		return
	var s: float
	if _t < POP_TIME:
		s = lerpf(0.5, 1.0, ease(_t / POP_TIME, 0.4)) + sin(_t / POP_TIME * PI) * 0.06
	elif _t < POP_TIME + HOLD_TIME:
		s = 1.0
	else:
		s = lerpf(1.0, 0.85, (_t - POP_TIME - HOLD_TIME) / CLOSE_TIME)
	var alpha := 1.0 if _t < POP_TIME + HOLD_TIME else 1.0 - (_t - POP_TIME - HOLD_TIME) / CLOSE_TIME
	modulate.a = alpha

	var text_w := maxf(DrawUtil.text_width(_title, TITLE_SIZE), DrawUtil.text_width(_message, MESSAGE_SIZE))
	var width := clampf(text_w + 120.0, MIN_WIDTH, MAX_WIDTH)
	var size := Vector2(width, HEIGHT)
	var center := ScreenLayout.DESKTOP_RECT.get_center() + Vector2(0, -10)
	draw_set_transform(center, 0.0, Vector2.ONE * s)

	var rect := Rect2(-size * 0.5, size)
	draw_rect(Rect2(rect.position + Vector2(8, 10), rect.size), Color(0, 0, 0, 0.35))
	ScreenLayout.draw_raised(self, rect, ScreenLayout.WINDOW_GREY, 3.0)
	var title_bar := Rect2(rect.position + Vector2(4, 4), Vector2(rect.size.x - 8, 24))
	ScreenLayout.draw_title_bar(self, title_bar)
	DrawUtil.text_left(self, tr("DIALOG_CAPTION"), Vector2(title_bar.position.x + 8, title_bar.get_center().y), 14, Color.WHITE)
	ScreenLayout.draw_window_buttons(self, title_bar, Vector2(18, 16))

	var icon_center := Vector2(rect.position.x + 50, rect.position.y + 74)
	_draw_icon(icon_center)

	var text_left := rect.position.x + 96
	var text_area := rect.size.x - 116
	DrawUtil.text_left(self, _title, Vector2(text_left, rect.position.y + 62), DrawUtil.fit_size(_title, TITLE_SIZE, text_area),
			_accent.darkened(0.45), -1, 1, _accent.darkened(0.45))
	DrawUtil.text_left(self, _message, Vector2(text_left, rect.position.y + 100), DrawUtil.fit_size(_message, MESSAGE_SIZE, text_area),
			ScreenLayout.TEXT_DARK)

	# OK button with focus frame
	var ok := Rect2(Vector2(-45, rect.end.y - 44), Vector2(90, 30))
	ScreenLayout.draw_raised(self, ok)
	draw_rect(ok.grow(2.0), ScreenLayout.TEXT_DARK, false, 1.0)
	DrawUtil.text_centered(self, tr("DIALOG_OK"), ok.get_center(), 16, ScreenLayout.TEXT_DARK)
	draw_set_transform(Vector2.ZERO)


func _draw_icon(c: Vector2) -> void:
	if _kind == Kind.WARNING:
		var tri := PackedVector2Array([c + Vector2(0, -24), c + Vector2(26, 20), c + Vector2(-26, 20)])
		draw_colored_polygon(tri, Color("ffd23f"))
		var outline := tri.duplicate()
		outline.append(tri[0])
		draw_polyline(outline, ScreenLayout.TEXT_DARK, 2.5)
		DrawUtil.text_centered(self, "!", c + Vector2(0, 5), 28, ScreenLayout.TEXT_DARK, 1, ScreenLayout.TEXT_DARK)
	else:
		draw_circle(c, 24, Color("2f5fd0"))
		draw_arc(c, 24, 0, TAU, 32, ScreenLayout.TEXT_DARK, 2.0)
		DrawUtil.text_centered(self, "i", c, 30, Color.WHITE, 1, Color.WHITE)
