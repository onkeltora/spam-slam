extends Node
## Dev tool: a bot that plays runs for balancing checks and screenshots.
## Only active when started with user args, e.g.:
##   godot --path . -- --autoplay --think=0.6 --accuracy=0.92
##   godot --path . -- --autoplay --shots=/tmp/shots --shot-times=2,12,30
##   godot --headless --path . -- --autoplay --runs=10 --think=0.5 --speed=4   (balancing stats only)
##   godot --headless --path . -- --autoplay --swipe-test   (input regression check)
##   godot --headless --path . -- --autoplay --rule-test    (every rule: matches, near-misses, override rate)

var main: Node
var think := 0.6            # seconds the bot needs per mail
var accuracy := 0.92        # chance to sort correctly
var runs := 1
var shots_dir := ""
var shot_times: Array[float] = [2.0, 12.0, 30.0]

var _timer := 0.0
var _run := 0
var _shot_index := 0
var _results: Array[Dictionary] = []


func _ready() -> void:
	GameManager.persist_highscore = false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--think="):
			think = arg.get_slice("=", 1).to_float()
		elif arg.begins_with("--accuracy="):
			accuracy = arg.get_slice("=", 1).to_float()
		elif arg.begins_with("--speed="):
			Engine.time_scale = arg.get_slice("=", 1).to_float()
		elif arg.begins_with("--runs="):
			runs = arg.get_slice("=", 1).to_int()
		elif arg.begins_with("--shots="):
			shots_dir = arg.get_slice("=", 1)
		elif arg.begins_with("--shot-times="):
			shot_times.clear()
			for t in arg.get_slice("=", 1).split(","):
				shot_times.append(t.to_float())
	if "--rule-test" in OS.get_cmdline_user_args():
		_rule_test()
		return
	if "--swipe-test" in OS.get_cmdline_user_args():
		_swipe_test()
		return
	GameManager.game_over.connect(_on_game_over)
	if shots_dir != "":
		# Event shots: capture the interesting moments whenever they happen.
		GameManager.baskets_swapped.connect(func(_a: int, _b: int) -> void: _delayed_shot("ev_reorg", 0.35))
		GameManager.boost_started.connect(func(_d: float) -> void: _delayed_shot("ev_boost", 0.5))
		GameManager.mail_sorted.connect(func(r: Dictionary) -> void:
			if not r.correct:
				_delayed_shot("ev_mistake", 0.15))
		DirAccess.make_dir_recursive_absolute(shots_dir)
		await get_tree().create_timer(0.6).timeout
		await _shot("00_title")
	_start()


func _start() -> void:
	_run += 1
	_timer = 0.0
	_shot_index = 0
	main.overlay.visible = false
	main._start_run()


func _process(delta: float) -> void:
	if not GameManager.running:
		return
	if shots_dir != "" and _shot_index < shot_times.size() and GameManager.elapsed >= shot_times[_shot_index]:
		_shot_index += 1
		_shot("%02d_t%d" % [_shot_index, roundi(GameManager.elapsed)])
	_timer += delta
	if _timer < think or main.queue.is_empty() or main.front_card == null:
		return
	_timer = 0.0
	var mail: MailData = main.queue[0]
	var correct_dir := main._dir_of_category(GameManager.get_correct_category(mail)) as int
	var dir := correct_dir
	if randf() > accuracy:
		while dir == correct_dir:
			dir = randi() % 4
	main._sort_front(dir)


func _on_game_over(reason: String) -> void:
	var result := {
		"reason": reason, "score": GameManager.score, "time": GameManager.elapsed,
		"sorted": GameManager.sorted_count, "accuracy": GameManager.get_accuracy(), "max_combo": GameManager.max_combo,
	}
	_results.append(result)
	print("[autoplay] run %d: %s" % [_run, result])
	if shots_dir != "":
		await get_tree().create_timer(0.5).timeout
		await _shot("90_collapse")
		await get_tree().create_timer(1.2).timeout
		await _shot("91_game_over")
	if _run < runs:
		await get_tree().create_timer(0.1).timeout
		_start()
		return
	var avg_time := 0.0
	var pile_deaths := 0
	for r in _results:
		avg_time += r.time
		pile_deaths += int(r.reason == "pile")
	print("[autoplay] %d runs  think=%.2f accuracy=%.2f  avg time %.1fs  pile deaths %d" % [
		_results.size(), think, accuracy, avg_time / _results.size(), pile_deaths])
	get_tree().quit()


func _delayed_shot(shot_name: String, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	await _shot("%s_t%d" % [shot_name, roundi(GameManager.elapsed)])


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := shots_dir.path_join(shot_name + ".png")
	get_viewport().get_texture().get_image().save_png(path)
	print("[autoplay] screenshot ", path)


# --- Swipe regression test: feeds synthetic touch + mouse events through the real input pipeline ---

func _swipe_test() -> void:
	set_process(false)
	_start()
	var failures := 0
	var cases := [
		# [name, use_mouse, distance, steps, expect_sort]
		["touch swipe 140px", false, 140.0, 10, true],
		["touch release after 60px", false, 60.0, 4, true],
		["touch tap 10px", false, 10.0, 2, false],
		["mouse drag 140px", true, 140.0, 10, true],
		["mouse tap", true, 5.0, 1, false],
	]
	for dir in 4:
		for c in cases:
			await get_tree().create_timer(0.3).timeout
			if main.front_card == null:
				main._spawn_mail()
				await get_tree().create_timer(0.3).timeout
			GameManager.spawn_pause = 99.0
			var mail: MailData = main.queue[0]
			var expected_category: int = GameManager.basket_layout[dir]
			var before := GameManager.sorted_count
			var correct_before := GameManager.correct_count
			var lives_before := GameManager.lives
			await _feed_swipe(dir, c[1], c[2], c[3])
			await get_tree().process_frame
			var sorted := GameManager.sorted_count - before
			var ok: bool = sorted == (1 if c[4] else 0)
			if ok and c[4]:
				var was_correct := GameManager.correct_count > correct_before
				ok = was_correct == (GameManager.get_correct_category(mail) == expected_category) or GameManager.active_rule != null
			GameManager.lives = maxi(GameManager.lives, lives_before)
			print("[swipe-test] dir=%s %-26s sorted=%d %s" % [GameManager.Dir.keys()[dir], c[0], sorted, "OK" if ok else "FAIL"])
			failures += int(not ok)
	print("[swipe-test] %s (%d failures)" % ["PASSED" if failures == 0 else "FAILED", failures])
	get_tree().quit(failures)


## Positions are given in canvas space (1280x720) and converted to window space,
## because Input.parse_input_event expects raw window coordinates.
func _feed_swipe(dir: int, use_mouse: bool, distance: float, steps: int) -> void:
	var to_window := get_viewport().get_final_transform()
	var vec: Vector2 = to_window.basis_xform([Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT][dir])
	var start := to_window * Vector2(640, 400)
	_send_press(start, true, use_mouse)
	for i in steps:
		await get_tree().create_timer(0.03).timeout
		var pos := start + vec * distance * (i + 1) / steps
		if use_mouse:
			var m := InputEventMouseMotion.new()
			m.position = pos
			m.global_position = pos
			m.button_mask = MOUSE_BUTTON_MASK_LEFT
			m.relative = vec * distance / steps
			m.velocity = vec * distance / steps / 0.03
			Input.parse_input_event(m)
		else:
			var d := InputEventScreenDrag.new()
			d.position = pos
			d.relative = vec * distance / steps
			d.velocity = vec * distance / steps / 0.03
			Input.parse_input_event(d)
	await get_tree().create_timer(0.03).timeout
	_send_press(start + vec * distance, false, use_mouse)


func _send_press(pos: Vector2, pressed: bool, use_mouse: bool) -> void:
	if use_mouse:
		var b := InputEventMouseButton.new()
		b.button_index = MOUSE_BUTTON_LEFT
		b.pressed = pressed
		b.position = pos
		b.global_position = pos
		Input.parse_input_event(b)
	else:
		var t := InputEventScreenTouch.new()
		t.pressed = pressed
		t.position = pos
		Input.parse_input_event(t)


# --- Rule test: every rule must produce real matches, real near-misses and actually change baskets ---

func _rule_test() -> void:
	set_process(false)
	var failures := 0
	var generator := MailGenerator.new()
	for rule in RulePool.create():
		var matched := 0
		var overridden := 0
		var bad_match := 0
		var bad_miss := 0
		for i in 400:
			var m := MailData.new()
			m.set_kind(randi() % 4)
			rule.make_match(m)
			bad_match += int(not rule.matches(m))
			var n := MailData.new()
			n.set_kind(randi() % 4)
			rule.make_near_miss(n)
			bad_miss += int(rule.matches(n))
			var g := generator.generate(rule)
			if rule.matches(g):
				matched += 1
				overridden += int(g.base_category() != rule.target)
		var ok := bad_match == 0 and bad_miss == 0 and matched > 120 and overridden > matched * 0.6
		failures += int(not ok)
		print("[rule-test] %-22s matches %3d/400  changes basket %3d  broken make_match %d  broken near_miss %d  %s" % [
			SortRule.Condition.keys()[rule.condition], matched, overridden, bad_match, bad_miss, "OK" if ok else "FAIL"])
	print("[rule-test] %s (%d failures)" % ["PASSED" if failures == 0 else "FAILED", failures])
	get_tree().quit(failures)
