extends Control
## Score (counting up) + combo/multiplier line, top-left.

var _score := 0
var _shown_score := 0.0
var _combo := 0
var _multiplier := 1
var _score_bump := 0.0
var _combo_bump := 0.0
var _combo_break := 0.0


func _ready() -> void:
	GameManager.score_changed.connect(func(s: int) -> void:
		if s > _score:
			_score_bump = 1.0
		_score = s
		if s == 0:
			_shown_score = 0.0)
	GameManager.combo_changed.connect(func(c: int, m: int) -> void:
		if c == 0 and _combo >= 3:
			_combo_break = 1.0
		elif c > _combo:
			_combo_bump = 1.0 if m > _multiplier else 0.5
		_combo = c
		_multiplier = m)
	GameManager.language_changed.connect(queue_redraw)


func _process(delta: float) -> void:
	_shown_score = move_toward(_shown_score, _score, maxf(absf(_score - _shown_score) * 12.0, 200.0) * delta)
	_score_bump = move_toward(_score_bump, 0.0, delta * 5.0)
	_combo_bump = move_toward(_combo_bump, 0.0, delta * 3.0)
	_combo_break = move_toward(_combo_break, 0.0, delta * 1.5)
	queue_redraw()


func _draw() -> void:
	DrawUtil.text_left(self, tr("HUD_SCORE"), Vector2(2, 12), 16, Color(0.95, 0.9, 0.75, 0.8), -1, 3)
	var score_size := int(40 * (1.0 + _score_bump * 0.12))
	DrawUtil.text_left(self, str(roundi(_shown_score)), Vector2(0, 44), score_size, Color("fff4d6"), -1, 7, Color("1a1208"))

	if _combo > 0 or _combo_break > 0.0:
		var text := tr("HUD_COMBO").format({"n": _combo, "m": _multiplier})
		var color := Color("ffb347").lerp(Color("ff5a3a"), clampf((_multiplier - 1) / 4.0, 0, 1))
		if _combo == 0:
			color = Color(0.6, 0.6, 0.6, _combo_break)
		var s := int(22 * (1.0 + _combo_bump * 0.35))
		var shake := Vector2(randf_range(-2, 2), 0) * _combo_break
		DrawUtil.text_left(self, text, Vector2(2, 82) + shake, s, color, -1, 5, Color("1a1208"))
