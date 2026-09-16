extends Control
## Boss challenge tracker: pops up when the golden boss mail was sorted,
## shows progress pips, then celebrates or sighs.

const RESULT_HOLD := 1.8

var _active := false
var _goal := 5
var _progress := 0
var _rewards_life := true
var _result_text := ""
var _result_success := false
var _result_timer := 0.0
var _appear := 0.0
var _time := 0.0


func _ready() -> void:
	GameManager.boss_challenge_started.connect(_on_started)
	GameManager.boss_challenge_progress.connect(func(p: int, g: int) -> void:
		_progress = p
		_goal = g)
	GameManager.boss_challenge_finished.connect(_on_finished)
	GameManager.game_started.connect(func() -> void:
		_active = false
		_result_timer = 0.0)


func _on_started(goal: int, rewards_life: bool) -> void:
	_active = true
	_goal = goal
	_progress = 0
	_rewards_life = rewards_life
	_result_timer = 0.0


func _on_finished(success: bool) -> void:
	_active = false
	_result_success = success
	_result_text = tr("BOSS_SUCCESS") if success else tr("BOSS_FAIL")
	_result_timer = RESULT_HOLD


func _process(delta: float) -> void:
	_time += delta
	_result_timer = maxf(_result_timer - delta, 0.0)
	var visible_target := 1.0 if (_active or _result_timer > 0.0) else 0.0
	_appear = move_toward(_appear, visible_target, delta * 6.0)
	queue_redraw()


func _draw() -> void:
	if _appear <= 0.0:
		return
	var offset := Vector2(0, (1.0 - ease(_appear, 0.4)) * 140.0)
	var rect := Rect2(offset, size)
	var gold := Color("f2c14e")
	DrawUtil.rounded_rect(self, Rect2(rect.position + Vector2(4, 5), rect.size), 10, Color(0, 0, 0, 0.35))
	DrawUtil.rounded_rect(self, rect, 10, Color("3a2d10"))
	DrawUtil.rounded_frame(self, rect, 10, gold.lerp(Color.WHITE, 0.3 + 0.3 * sin(_time * 5.0)), 3)

	# Tiny boss avatar
	var face := rect.position + Vector2(34, size.y * 0.5)
	draw_circle(face, 22, Color("e8c39e"))
	draw_rect(Rect2(face + Vector2(-22, -24), Vector2(44, 10)), Color("3a2a1a"))
	draw_circle(face + Vector2(-8, -3), 3, Color.BLACK)
	draw_circle(face + Vector2(8, -3), 3, Color.BLACK)
	draw_line(face + Vector2(-14, -10), face + Vector2(-3, -7), Color.BLACK, 2.5)
	draw_line(face + Vector2(14, -10), face + Vector2(3, -7), Color.BLACK, 2.5)
	draw_line(face + Vector2(-7, 10), face + Vector2(7, 10), Color.BLACK, 2.5)

	var text_x := rect.position.x + 66
	var text_w := size.x - 76
	if _result_timer > 0.0 and not _active:
		var color := Color("7dff8a") if _result_success else Color(0.8, 0.75, 0.65)
		DrawUtil.text_left(self, _result_text, Vector2(text_x, rect.get_center().y), DrawUtil.fit_size(_result_text, 22, text_w), color, -1, 4)
		return

	var challenge := tr("BOSS_CHALLENGE").format({"goal": _goal})
	DrawUtil.text_left(self, challenge, Vector2(text_x, rect.position.y + 20), DrawUtil.fit_size(challenge, 18, text_w), Color.WHITE)
	var reward := tr("BOSS_REWARD_LIFE") if _rewards_life else tr("BOSS_REWARD_SCORE").format({"v": GameManager.BOSS_SCORE_REWARD})
	DrawUtil.text_left(self, reward, Vector2(text_x, rect.position.y + 43), 15, gold)
	for i in _goal:
		var c := rect.position + Vector2(text_x - rect.position.x + 9 + i * 24, size.y - 18)
		if i < _progress:
			draw_circle(c, 8, gold)
		else:
			draw_arc(c, 7, 0, TAU, 16, Color(gold, 0.6), 2.0)
