extends Control
## Permanent display of the active special rule, colored by its target basket.

var _rule: SortRule = null
var _pulse := 0.0


func _ready() -> void:
	GameManager.rule_changed.connect(func(rule: SortRule) -> void:
		_rule = rule
		if rule != null:
			_pulse = 1.0)
	GameManager.language_changed.connect(queue_redraw)


func pulse() -> void:
	_pulse = 1.0


func _process(delta: float) -> void:
	_pulse = move_toward(_pulse, 0.0, delta * 1.5)
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var accent: Color = Color(0.55, 0.55, 0.55) if _rule == null else MailData.CATEGORY_COLORS[_rule.target]
	DrawUtil.rounded_rect(self, Rect2(rect.position + Vector2(4, 5), rect.size), 10, Color(0, 0, 0, 0.35))
	DrawUtil.rounded_rect(self, rect, 10, Color(0.1, 0.1, 0.12, 0.92).lerp(accent.darkened(0.4), _pulse * 0.6))
	DrawUtil.rounded_frame(self, rect, 10, accent.lerp(Color.WHITE, _pulse * 0.5), 3)

	if _rule == null:
		var hint := tr("HUD_RULE_NONE")
		DrawUtil.text_centered(self, hint, rect.get_center(), DrawUtil.fit_size(hint, 20, size.x - 30), Color(0.8, 0.8, 0.78))
		return

	# "RULE" tag on the left, rule text centered in the rest
	var tag := tr("HUD_RULE")
	var tag_w := DrawUtil.text_width(tag, 16) + 20
	var tag_rect := Rect2(6, 6, tag_w, size.y - 12)
	DrawUtil.rounded_rect(self, tag_rect, 6, accent)
	DrawUtil.text_centered(self, tag, tag_rect.get_center(), 16, Color(0.08, 0.08, 0.08))

	var text := _rule.get_text()
	var area := Rect2(tag_rect.end.x + 8, 0, size.x - tag_rect.end.x - 16, size.y)
	var text_size := DrawUtil.fit_size(text, 25, area.size.x)
	DrawUtil.text_centered(self, text, area.get_center(), text_size, Color.WHITE.lerp(accent, 0.25), 4, Color.BLACK)
