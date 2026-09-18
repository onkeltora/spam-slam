extends Node2D
## Boss challenge as an OCQ messenger notification that slides up from behind
## the taskbar: shows the goal and progress pips, then praises or sighs.

const SIZE := Vector2(262, 104)
const RESULT_HOLD := 1.8
const MARGIN := 6.0

var _active := false
var _goal := 5
var _progress := 0
var _rewards_life := true
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
	_result_timer = RESULT_HOLD


func _process(delta: float) -> void:
	_time += delta
	_result_timer = maxf(_result_timer - delta, 0.0)
	var target := 1.0 if (_active or _result_timer > 0.0) else 0.0
	_appear = move_toward(_appear, target, delta * 5.0)
	queue_redraw()


func _draw() -> void:
	if _appear <= 0.0:
		return
	var taskbar := ScreenLayout.taskbar_rect()
	var rest := Vector2(taskbar.end.x - SIZE.x - MARGIN, taskbar.position.y - SIZE.y - MARGIN)
	var hidden_y := taskbar.position.y + 4.0
	var pos := Vector2(rest.x, lerpf(hidden_y, rest.y, ease(_appear, 0.4)))
	var rect := Rect2(pos, SIZE)

	var has_monitor: bool = EraManager.current().has_monitor
	draw_rect(Rect2(rect.position + Vector2(5, 6), rect.size), Color(0, 0, 0, 0.3))
	var body_top: float
	if has_monitor:
		ScreenLayout.draw_raised(self, rect)
		var title := Rect2(rect.position + Vector2(3, 3), Vector2(rect.size.x - 6, 20))
		ScreenLayout.draw_title_bar(self, title, Color("1f6a2a"), Color("5cb85c"))
		AppIcons.draw_flower(self, Vector2(title.position.x + 11, title.get_center().y), 7.5)
		DrawUtil.text_left(self, tr("MESSENGER_TITLE"), Vector2(title.position.x + 22, title.get_center().y), 13, Color.WHITE)
		ScreenLayout.draw_window_buttons(self, title, Vector2(16, 14))
		body_top = title.end.y + 4
	else:
		draw_rect(rect, Color("f2e6c9"))
		draw_rect(rect, Color("cdbb8c"), false, 2.0)
		draw_circle(Vector2(rect.position.x + 13, rect.position.y + 13), 6.0, Color("8a1f1f"))
		body_top = rect.position.y + 22
	_draw_boss_avatar(Vector2(rect.position.x + 30, body_top + 34))

	var text_x := rect.position.x + 60
	var text_w := SIZE.x - 68
	DrawUtil.text_left(self, tr("BOSS_SAYS"), Vector2(text_x, body_top + 10), 13, Color("55524a"))

	if _result_timer > 0.0 and not _active:
		var result := tr("BOSS_SUCCESS") if _result_success else tr("BOSS_FAIL")
		var color := Color("1f7a2e") if _result_success else ScreenLayout.TEXT_DARK
		DrawUtil.text_left(self, result, Vector2(text_x, body_top + 36), DrawUtil.fit_size(result, 18, text_w), color, -1, 1, color)
		return

	var challenge := tr("BOSS_CHALLENGE").format({"goal": _goal})
	DrawUtil.text_left(self, challenge, Vector2(text_x, body_top + 30), DrawUtil.fit_size(challenge, 17, text_w),
			ScreenLayout.TEXT_DARK, -1, 1, ScreenLayout.TEXT_DARK)
	var reward := tr("BOSS_REWARD_LIFE") if _rewards_life else tr("BOSS_REWARD_SCORE").format({"v": GameManager.BOSS_SCORE_REWARD})
	DrawUtil.text_left(self, reward, Vector2(text_x, body_top + 50), 14, Color("8a5a00"))
	for i in _goal:
		var c := Vector2(text_x + 8 + i * 22, body_top + 70)
		if i < _progress:
			draw_circle(c, 7, Color("e0a820"))
		draw_arc(c, 7, 0, TAU, 16, Color("5a4a20"), 2.0)


func _draw_boss_avatar(face: Vector2) -> void:
	ScreenLayout.draw_sunken(self, Rect2(face - Vector2(24, 26), Vector2(48, 52)), Color("8fb4d8"), 1.5)
	draw_circle(face + Vector2(0, 2), 17, Color("e8c39e"))
	draw_rect(Rect2(face + Vector2(-17, -17), Vector2(34, 8)), Color("3a2a1a"))
	draw_circle(face + Vector2(-6, 0), 2.5, Color.BLACK)
	draw_circle(face + Vector2(6, 0), 2.5, Color.BLACK)
	draw_line(face + Vector2(-11, -6), face + Vector2(-2, -4), Color.BLACK, 2.0)
	draw_line(face + Vector2(11, -6), face + Vector2(2, -4), Color.BLACK, 2.0)
	var mouth := face + Vector2(0, 10)
	if _result_timer > 0.0 and not _active and _result_success:
		draw_arc(mouth + Vector2(0, -4), 6, PI * 0.15, PI * 0.85, 8, Color.BLACK, 2.0)
	else:
		draw_line(mouth + Vector2(-6, 0), mouth + Vector2(6, 0), Color.BLACK, 2.0)
