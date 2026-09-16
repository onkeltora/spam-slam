extends Node2D
## The active special rule as the boss's Post-it, stuck to the side of the monitor.
## A new rule rips the old note off and slaps a fresh one on.

const SIZE := Vector2(164, 176)
const TILT := -0.05
const PAPER := Color("fff27a")
const PAPER_SHADE := Color("f0dc55")
const INK := Color("2a2a6a")
const TEXT_WIDTH := 140.0
const TEXT_SIZE := 17

var _rule: SortRule = null
var _slap := 0.0       # 1 -> 0 when a new note is slapped on
var _old_rule: SortRule = null
var _rip := 0.0        # 1 -> 0 while the old note flies off
var _time := 0.0


func _ready() -> void:
	GameManager.rule_changed.connect(_on_rule_changed)
	GameManager.baskets_swapped.connect(func(_a: int, _b: int) -> void: _slap = 0.6)
	GameManager.language_changed.connect(queue_redraw)


func _on_rule_changed(rule: SortRule) -> void:
	if rule == _rule:
		return
	_old_rule = _rule
	_rip = 1.0 if _old_rule != null else 0.0
	_rule = rule
	_slap = 1.0


func _process(delta: float) -> void:
	_time += delta
	_slap = move_toward(_slap, 0.0, delta * 3.5)
	_rip = move_toward(_rip, 0.0, delta * 2.5)
	queue_redraw()


func _draw() -> void:
	if _rip > 0.0:
		var k := 1.0 - _rip
		draw_set_transform(Vector2(k * 160.0, k * k * 500.0), TILT + k * 2.5, Vector2.ONE)
		_draw_note(_old_rule, 1.0 - k * 0.3)
	var s := 1.0 + ease(_slap, 2.0) * 0.5
	draw_set_transform(Vector2.ZERO, TILT + sin(_slap * PI) * 0.12, Vector2.ONE * s)
	_draw_note(_rule, 1.0)
	draw_set_transform(Vector2.ZERO)


func _draw_note(rule: SortRule, alpha: float) -> void:
	var rect := Rect2(-SIZE * 0.5, SIZE)
	draw_rect(Rect2(rect.position + Vector2(5, 7), rect.size), Color(0, 0, 0, 0.3 * alpha))
	draw_rect(rect, Color(PAPER, alpha))
	# Curled bottom corner
	var curl := PackedVector2Array([rect.end - Vector2(26, 0), rect.end - Vector2(0, 26), rect.end])
	draw_colored_polygon(curl, Color(PAPER_SHADE, alpha))
	draw_rect(Rect2(rect.position, Vector2(SIZE.x, 22)), Color(PAPER_SHADE, alpha * 0.8))

	var x := rect.position.x + 12
	var y := rect.position.y + 11
	var header := tr("HUD_RULE") + ":" if rule != null else tr("HUD_RULE")
	DrawUtil.text_left(self, header, Vector2(x, y), 15, Color(INK, alpha), -1, 1, Color(INK, alpha))

	var f := DrawUtil.font()
	if rule == null:
		var hint := tr("HUD_RULE_NONE")
		draw_multiline_string(f, Vector2(x, y + 36), hint, HORIZONTAL_ALIGNMENT_LEFT, TEXT_WIDTH, TEXT_SIZE, 5, Color(INK, alpha * 0.8))
		return

	var cond := rule.get_condition_text()
	var cond_size := TEXT_SIZE
	while cond_size > 12 and f.get_multiline_string_size(cond, HORIZONTAL_ALIGNMENT_LEFT, TEXT_WIDTH, cond_size).y > 88.0:
		cond_size -= 1
	draw_multiline_string(f, Vector2(x, y + 36), cond, HORIZONTAL_ALIGNMENT_LEFT, TEXT_WIDTH, cond_size, 5, Color(INK, alpha))

	# Arrow + target folder chip at the bottom
	var accent: Color = MailData.CATEGORY_COLORS[rule.target]
	var target_text := tr(MailData.CATEGORY_KEYS[rule.target])
	var chip_y := rect.end.y - 30
	DrawUtil.text_left(self, "→", Vector2(x, chip_y), 22, Color(INK, alpha), -1, 1, Color(INK, alpha))
	var chip_size := DrawUtil.fit_size(target_text, 18, TEXT_WIDTH - 36)
	var chip := Rect2(x + 26, chip_y - 13, DrawUtil.text_width(target_text, chip_size) + 12, 26)
	draw_rect(chip, Color(accent, alpha))
	draw_rect(chip, Color(0, 0, 0, 0.5 * alpha), false, 1.5)
	DrawUtil.text_left(self, target_text, Vector2(chip.position.x + 6, chip_y), chip_size, Color(0.08, 0.08, 0.08, alpha))
