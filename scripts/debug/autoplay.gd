extends Node
## Dev tool: a bot that plays runs for balancing checks and screenshots.
## Only active when started with user args, e.g.:
##   godot --path . -- --autoplay --think=0.6 --accuracy=0.92
##   godot --path . -- --autoplay --shots=/tmp/shots --shot-times=2,12,30
##   godot --headless --path . -- --autoplay --runs=10 --think=0.5 --speed=4   (balancing stats only)
##   godot --headless --path . -- --autoplay --swipe-test   (input regression check)
##   godot --headless --path . -- --autoplay --rule-test    (every rule: matches, near-misses, override rate)
##   godot --path . -- --autoplay --music-test               (MusicManager playlist/bus/muffle, silent tracks)
##   godot --path . -- --autoplay --card-gallery --shots=DIR  (screenshots of tricky mail layouts + dialogs)
##   godot --headless --path . -- --autoplay --sound-test     (SoundManager: every game event plays its slot)
##   godot --path . -- --autoplay --app-test [--shots=DIR]    (desktop programs via real taps/swipes)

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
		elif arg.begins_with("--lang="):
			TranslationServer.set_locale(arg.get_slice("=", 1))  # not saved
		elif arg == "--crt=off":
			main.get_node("World/CRT").enabled = false
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
	if shots_dir != "":
		DirAccess.make_dir_recursive_absolute(shots_dir)
	if "--app-test" in OS.get_cmdline_user_args():
		_app_test()
		return
	if "--sound-test" in OS.get_cmdline_user_args():
		_sound_test()
		return
	if "--card-gallery" in OS.get_cmdline_user_args():
		_card_gallery()
		return
	if "--music-test" in OS.get_cmdline_user_args():
		_music_test()
		return
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


# --- Music test: silent in-memory tracks, checks playlist order, bus routing and muffle ---

func _music_test() -> void:
	set_process(false)
	var failures := 0
	var mm := MusicManager
	var tracks: Array[AudioStream] = [_silent_track(0.25), null, _silent_track(0.25), _silent_track(0.25)]
	mm.playlist = tracks
	mm.shuffle = false
	var played: Array[int] = []
	var record := func() -> void: played.append(tracks.find(mm.player.stream))
	mm.play()
	record.call()
	var last_stream: AudioStream = mm.player.stream
	var t := 0.0
	while t < 1.6 and played.size() < 5:
		await get_tree().process_frame
		t += get_process_delta_time()
		if mm.player.stream != last_stream:
			last_stream = mm.player.stream
			record.call()
	failures += _check("playlist order skips empty slot and wraps", played.slice(0, 4) == [0, 2, 3, 0], str(played))
	failures += _check("player routed to Music bus", mm.player.bus == &"Music", str(mm.player.bus))
	var bus := AudioServer.get_bus_index(&"Music")
	failures += _check("Music bus + SFX bus exist", bus != -1 and AudioServer.get_bus_index(&"SFX") != -1, "")
	failures += _check("muffled on title (low-pass on)", AudioServer.is_bus_effect_enabled(bus, mm._lowpass_index) and mm._muffle > 0.99, "muffle=%.2f" % mm._muffle)

	GameManager.start_game()
	await get_tree().create_timer(mm.muffle_fade_time + 0.2).timeout
	var lowpass := AudioServer.get_bus_effect(bus, mm._lowpass_index) as AudioEffectLowPassFilter
	failures += _check("clear during run (low-pass off)", not AudioServer.is_bus_effect_enabled(bus, mm._lowpass_index) and mm._muffle < 0.01, "cutoff=%d" % lowpass.cutoff_hz)
	failures += _check("faded in to target volume", absf(mm.player.volume_db - mm.volume_db) < 0.1, "%.1f dB" % mm.player.volume_db)

	GameManager._end_game("lives")
	await get_tree().create_timer(mm.muffle_fade_time + 0.2).timeout
	failures += _check("muffled after game over", mm._muffle > 0.99 and absf(lowpass.cutoff_hz - mm.muffled_cutoff_hz) < 1.0, "cutoff=%d" % lowpass.cutoff_hz)
	failures += _check("quieter when muffled", absf(mm.player.volume_db - (mm.volume_db + mm.muffled_volume_offset_db)) < 0.1, "%.1f dB" % mm.player.volume_db)

	mm.shuffle = true
	var repeats := 0
	for i in 200:
		var before: int = mm._order.back()
		mm._build_order(before)
		repeats += int(mm._order[0] == before)
	failures += _check("shuffle never repeats a track across playlist wrap", repeats == 0, "%d repeats" % repeats)

	mm.stop(0.2)
	await get_tree().create_timer(0.4).timeout
	failures += _check("stop fades out and stops", not mm.player.playing, "")
	print("[music-test] %s (%d failures)" % ["PASSED" if failures == 0 else "FAILED", failures])
	get_tree().quit(failures)


func _check(label: String, ok: bool, detail: String) -> int:
	print("[music-test] %-52s %s %s" % [label, "OK" if ok else "FAIL", detail])
	return int(not ok)


func _silent_track(seconds: float) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	var data := PackedByteArray()
	data.resize(int(seconds * wav.mix_rate) * 2)
	wav.data = data
	return wav


# --- Card gallery: screenshots of hand-picked mails that stress the card layout ---

func _card_gallery() -> void:
	set_process(false)
	_start()
	GameManager.spawn_pause = 999.0
	await get_tree().create_timer(0.6).timeout
	var cases := {}

	var m := MailData.new()
	m.set_kind(MailData.SenderKind.NEWSLETTER)
	m.sender_index = 1
	m.subject_index = 1
	m.has_cat = true
	m.set_smiley_count(4)
	cases["smileys_cat"] = m

	m = MailData.new()
	m.set_kind(MailData.SenderKind.STRANGER)
	m.subject_index = 3
	m.caps = true
	m.exclusive = true
	m.set_smiley_count(5)
	m.set_digits_in_address(true)
	m.biz_domain = true
	cases["long_caps_wrap"] = m

	m = MailData.new()
	m.set_kind(MailData.SenderKind.SECURITY)
	m.lookalike_company_domain = true
	m.urgent = true
	m.attachment_ext = "exe"
	m.amount = 12500
	cases["all_extras_lookalike"] = m

	m = MailData.new()
	m.set_kind(MailData.SenderKind.COMPANY)
	m.is_boss = true
	cases["boss"] = m

	for shot_name in cases:
		for card in main.cards.get_children():
			card.queue_free()
		main.queue.clear()
		main.front_card = null
		main.queue.append(cases[shot_name])
		main._bring_next_to_front(false)
		await get_tree().create_timer(0.5).timeout
		await _shot("gallery_" + shot_name)

	# Dialogs + boss toast
	GameManager.active_rule = SortRule.create(SortRule.Condition.CAT, MailData.Category.IMPORTANT)
	GameManager.rule_changed.emit(GameManager.active_rule)
	GameManager._start_boss_challenge()
	GameManager.boss_challenge_progress.emit(2, GameManager.BOSS_GOAL)
	GameManager.boss_progress = 2
	await get_tree().create_timer(0.6).timeout
	await _shot("gallery_dialog_rule_toast")
	GameManager._reorg_baskets()
	await get_tree().create_timer(0.3).timeout
	await _shot("gallery_reorg_moving")
	GameManager.lives = 1
	GameManager._end_game("lives")
	await get_tree().create_timer(0.35).timeout
	await _shot("gallery_power_off")
	await get_tree().create_timer(1.3).timeout
	await _shot("gallery_game_over_overlay")
	get_tree().quit()


# --- Sound test: every slot gets its own silent stream, events are triggered through real gameplay ---

func _sound_test() -> void:
	set_process(false)
	var failures := 0
	var sm := SoundManager
	var streams := {}
	for sound in sm.Sound.values():
		var event: SoundEvent = sm.get_event(sound)
		failures += _sound_check("slot %s exists in sound_manager.tscn" % sm.Sound.keys()[sound], event != null, "")
		if event == null:
			continue
		var stream := _silent_track(1.0)
		event.streams = [stream]
		event.min_interval = 0.0
		streams[sound] = stream
	failures += _sound_check("all voices on SFX bus", sm._voices.all(func(v: AudioStreamPlayer) -> bool: return v.bus == &"SFX"), "")

	GameManager.spawn_pause = 999.0
	_start()
	GameManager.spawn_pause = 999.0
	await get_tree().process_frame
	failures += _sound_check("NEW_POPUP when a mail comes to the front", _is_sounding(streams[sm.Sound.NEW_POPUP]), "")

	_stop_all_voices()
	var mail: MailData = main.queue[0]
	main._spawn_mail()  # so a next mail can come forward
	main._sort_front(main._dir_of_category(GameManager.get_correct_category(mail)))
	await get_tree().process_frame
	failures += _sound_check("SORTED on correct sort", _is_sounding(streams[sm.Sound.SORTED]), "")
	failures += _sound_check("NEW_POPUP again for the next mail", _is_sounding(streams[sm.Sound.NEW_POPUP]), "")

	_stop_all_voices()
	mail = main.queue[0]
	var wrong: int = (main._dir_of_category(GameManager.get_correct_category(mail)) + 1) % 4
	main._spawn_mail()
	main._sort_front(wrong)
	await get_tree().process_frame
	failures += _sound_check("MISTAKE on wrong sort", _is_sounding(streams[sm.Sound.MISTAKE]), "")

	_stop_all_voices()
	GameManager._advance_rule()
	failures += _sound_check("NEW_RULE on rule change", _is_sounding(streams[sm.Sound.NEW_RULE]), "")
	_stop_all_voices()
	GameManager._reorg_baskets()
	failures += _sound_check("NEW_RULE on folder reorg", _is_sounding(streams[sm.Sound.NEW_RULE]), "")

	_stop_all_voices()
	GameManager.boost_started.emit(GameManager.BOOST_DURATION)
	failures += _sound_check("COFFEE_BOOST on boost", _is_sounding(streams[sm.Sound.COFFEE_BOOST]), "")

	_stop_all_voices()
	GameManager._start_boss_challenge()
	failures += _sound_check("OCQ_MESSAGE when boss challenge appears", _is_sounding(streams[sm.Sound.OCQ_MESSAGE]), "")
	_stop_all_voices()
	GameManager._finish_boss_challenge(false)
	failures += _sound_check("no BONUS when boss challenge fails", not _is_sounding(streams[sm.Sound.BONUS]), "")
	failures += _sound_check("OCQ_MESSAGE right away on boss *sigh*", _is_sounding(streams[sm.Sound.OCQ_MESSAGE]), "")
	GameManager._start_boss_challenge()
	_stop_all_voices()
	GameManager._finish_boss_challenge(true)
	failures += _sound_check("BONUS when boss challenge succeeds", _is_sounding(streams[sm.Sound.BONUS]), "")
	failures += _sound_check("OCQ reply not yet (masked by bonus)", not _is_sounding(streams[sm.Sound.OCQ_MESSAGE]), "")
	await get_tree().create_timer(sm.OCQ_AFTER_BONUS_DELAY + 0.1).timeout
	failures += _sound_check("OCQ reply follows shortly after the bonus", _is_sounding(streams[sm.Sound.OCQ_MESSAGE]), "")

	_stop_all_voices()
	main.app_windows.open_app("aoff", Rect2(Vector2(270, 60), Vector2(90, 70)))
	failures += _sound_check("APP_OPEN when a desktop program opens", _is_sounding(streams[sm.Sound.APP_OPEN]), "")
	await get_tree().create_timer(RetroWindow.OPEN_TIME + AoffDialupWindow.DIAL_PRESS + 0.2).timeout
	failures += _sound_check("AOFF_DIALUP when AOFF starts dialing", _is_sounding(streams[sm.Sound.AOFF_DIALUP]), "")
	main.app_windows.close_window()
	failures += _sound_check("closing AOFF mid-dial cuts the modem", not _is_sounding(streams[sm.Sound.AOFF_DIALUP]), "")
	await get_tree().create_timer(0.2).timeout

	_stop_all_voices()
	GameManager._end_game("pile")
	await get_tree().process_frame
	failures += _sound_check("PILE_CRASH on inbox overflow", _is_sounding(streams[sm.Sound.PILE_CRASH]), "")
	failures += _sound_check("no NO_LIVES on inbox overflow", not _is_sounding(streams[sm.Sound.NO_LIVES]), "")

	_stop_all_voices()
	_start()
	GameManager.spawn_pause = 999.0
	await get_tree().process_frame
	_stop_all_voices()
	GameManager.lives = 1
	mail = main.queue[0]
	wrong = (main._dir_of_category(GameManager.get_correct_category(mail)) + 1) % 4
	main._sort_front(wrong)
	await get_tree().process_frame
	failures += _sound_check("NO_LIVES on last life lost", _is_sounding(streams[sm.Sound.NO_LIVES]), "")
	failures += _sound_check("no MISTAKE layered on the fatal mistake", not _is_sounding(streams[sm.Sound.MISTAKE]), "")

	# Variants, pitch spread, min interval and voice stealing
	var event: SoundEvent = sm.sorted
	var a := _silent_track(1.0)
	var b := _silent_track(1.0)
	event.streams = [a, null, b]
	event.pitch_variation = 0.05
	event.combo_pitch_step = 0.0
	var picked := {}
	var pitch_ok := true
	for i in 60:
		_stop_all_voices()
		sm.play(sm.Sound.SORTED)
		for v in sm._voices:
			if v.playing:
				picked[v.stream] = true
				pitch_ok = pitch_ok and absf(v.pitch_scale - 1.0) <= 0.0501
	failures += _sound_check("random pick uses all variants, skips empty slot", picked.size() == 2 and not picked.has(null), "%d variants" % picked.size())
	failures += _sound_check("pitch stays within ±variation", pitch_ok, "")

	_stop_all_voices()
	event.min_interval = 10.0
	event.last_played_msec = -100000
	sm.play(sm.Sound.SORTED)
	sm.play(sm.Sound.SORTED)
	failures += _sound_check("min_interval blocks rapid repeats", _playing_count() == 1, "%d playing" % _playing_count())

	_stop_all_voices()
	event.min_interval = 0.0
	for i in 20:
		sm.play(sm.Sound.SORTED)
	failures += _sound_check("20 rapid plays fill the voice pool without errors", _playing_count() == sm.VOICES, "%d playing" % _playing_count())

	_stop_all_voices()
	print("[sound-test] %s (%d failures)" % ["PASSED" if failures == 0 else "FAILED", failures])
	get_tree().quit(failures)


func _is_sounding(stream: AudioStream) -> bool:
	return SoundManager._voices.any(func(v: AudioStreamPlayer) -> bool: return v.playing and v.stream == stream)


func _playing_count() -> int:
	return SoundManager._voices.filter(func(v: AudioStreamPlayer) -> bool: return v.playing).size()


func _stop_all_voices() -> void:
	for v in SoundManager._voices:
		v.stop()


func _sound_check(label: String, ok: bool, detail: String) -> int:
	print("[sound-test] %-52s %s %s" % [label, "OK" if ok else "FAIL", detail])
	return int(not ok)


# --- App test: desktop programs, driven by real touch/key events ---

func _app_test() -> void:
	set_process(false)
	var failures := 0
	var aw: AppWindows = main.app_windows
	var desk: Node2D = main.desktop
	_start()
	GameManager.spawn_pause = 999.0
	await get_tree().create_timer(0.4).timeout

	await _tap_world(desk.ICONS.cat)
	failures += _app_check("single tap only selects the icon", desk.selected == "cat" and not aw.is_open(), "")
	await get_tree().create_timer(0.6).timeout

	await _double_tap_world(desk.ICONS.cat)
	failures += _app_check("double tap opens the image viewer", aw.current is CatViewerWindow, "")
	failures += _app_check("taskbar shows the program", main.taskbar._app_title != "", main.taskbar._app_title)
	var elapsed_before := GameManager.elapsed
	await get_tree().create_timer(0.6).timeout
	failures += _app_check("game keeps running while it is open", GameManager.elapsed > elapsed_before + 0.4, "")
	if shots_dir != "":
		await _shot("app_cat_viewer")

	await _tap_world(aw.current.window_rect.get_center())
	failures += _app_check("tap inside the window keeps it open", aw.is_open(), "")

	var sorted_before := GameManager.sorted_count
	await _feed_swipe(GameManager.Dir.RIGHT, false, 140.0, 8)
	await get_tree().create_timer(0.25).timeout
	failures += _app_check("swipe closes the program", not aw.is_open() and aw.current == null, "")
	failures += _app_check("...without sorting the mail", GameManager.sorted_count == sorted_before, "")
	failures += _app_check("taskbar button disappears", main.taskbar._app_title == "", "")
	await _feed_swipe(main._dir_of_category(GameManager.get_correct_category(main.queue[0])), false, 140.0, 8)
	await get_tree().create_timer(0.1).timeout
	failures += _app_check("next swipe sorts again", GameManager.sorted_count == sorted_before + 1, "")

	await _double_tap_world(desk.ICONS.aoff)
	failures += _app_check("double tap opens AOFF sign-on", aw.current is AoffDialupWindow, "")
	await get_tree().create_timer(1.9).timeout
	if shots_dir != "":
		await _shot("app_aoff_typing")
	await get_tree().create_timer(4.6).timeout
	failures += _app_check("AOFF ends with a busy line", aw.current.current_step() == AoffDialupWindow.Step.BUSY, "")
	if shots_dir != "":
		await _shot("app_aoff_busy")
	await _tap_world(aw.current.close_button_rect().get_center())
	await get_tree().create_timer(0.25).timeout
	failures += _app_check("X button closes the program", not aw.is_open(), "")

	GameManager._start_boss_challenge()
	GameManager._finish_boss_challenge(true)
	GameManager._start_boss_challenge()
	await get_tree().create_timer(0.6).timeout
	await _double_tap_world(desk.ICONS.ocq)
	failures += _app_check("double tap opens OCQ", aw.current is OcqWindow, "")
	failures += _app_check("OCQ has this run's boss messages", aw.current.history.size() == 3, "%d entries" % aw.current.history.size())
	await get_tree().create_timer(0.4).timeout
	if shots_dir != "":
		await _shot("app_ocq")
	sorted_before = GameManager.sorted_count
	var key := InputEventKey.new()
	key.keycode = KEY_RIGHT
	key.pressed = true
	Input.parse_input_event(key)
	await get_tree().create_timer(0.25).timeout
	failures += _app_check("arrow key closes without sorting", not aw.is_open() and GameManager.sorted_count == sorted_before, "")

	await get_tree().create_timer(0.6).timeout
	await _double_tap_world(desk.ICONS.whipamp)
	failures += _app_check("double tap opens WhipAmp", aw.current is WhipAmpWindow, "")
	var amp: WhipAmpWindow = aw.current
	var volume_before := MusicManager.get_user_volume()
	await get_tree().create_timer(0.4).timeout
	await _tap_world(amp._button_rect(2).get_center())
	var paused_at := MusicManager.get_position()
	failures += _app_check("WhipAmp pause pauses the music", MusicManager.is_paused(), "")
	await get_tree().create_timer(0.3).timeout
	failures += _app_check("paused position holds and is shown", MusicManager.get_position() > 0.0
			and absf(MusicManager.get_position() - paused_at) < 0.05, "%.2fs" % MusicManager.get_position())
	await _tap_world(amp._button_rect(1).get_center())
	failures += _app_check("WhipAmp play resumes where it paused", MusicManager.is_playing() and not MusicManager.is_paused()
			and MusicManager.get_position() >= paused_at, "")
	await _tap_world(amp._button_rect(3).get_center())
	await get_tree().create_timer(0.4).timeout
	failures += _app_check("WhipAmp stop stops", not MusicManager.is_playing(), "")
	await _tap_world(amp._button_rect(1).get_center())
	await get_tree().create_timer(0.2).timeout
	failures += _app_check("WhipAmp play after stop restarts", MusicManager.is_playing(), "")
	await _tap_world(amp._seek_rect().position + amp._seek_rect().size * Vector2(0.5, 0.5))
	await get_tree().create_timer(0.1).timeout
	var half := MusicManager.get_length() * 0.5
	failures += _app_check("tap on seek bar jumps in the track", absf(MusicManager.get_position() - half) < 1.5,
			"%.1fs of %.1fs" % [MusicManager.get_position(), MusicManager.get_length()])
	await _tap_world(amp._button_rect(4).get_center())
	await get_tree().create_timer(0.1).timeout
	failures += _app_check("WhipAmp next starts a (new) track from the top", MusicManager.get_position() < 1.0, "%.1fs" % MusicManager.get_position())
	await _tap_world(amp._button_rect(0).get_center())
	await get_tree().create_timer(0.1).timeout
	failures += _app_check("WhipAmp prev works too", MusicManager.is_playing() and MusicManager.get_position() < 1.0, "")
	var vol := amp._volume_rect()
	await _tap_world(vol.position + Vector2(vol.size.x * 0.25, vol.size.y * 0.5))
	failures += _app_check("tap on volume slider sets volume", absf(MusicManager.get_user_volume() - 0.25) < 0.03, "%.2f" % MusicManager.get_user_volume())
	await get_tree().create_timer(0.8).timeout
	if shots_dir != "":
		await _shot("app_whipamp")
	MusicManager.set_user_volume(volume_before)
	sorted_before = GameManager.sorted_count
	await _feed_swipe(GameManager.Dir.LEFT, false, 140.0, 8)
	await get_tree().create_timer(0.25).timeout
	failures += _app_check("swipe closes WhipAmp, music keeps playing", not aw.is_open() and MusicManager.is_playing()
			and GameManager.sorted_count == sorted_before, "")

	await get_tree().create_timer(0.6).timeout
	await _double_tap_world(desk.ICONS.cat)
	GameManager._end_game("lives")
	await get_tree().process_frame
	await get_tree().process_frame
	failures += _app_check("game over closes the program", not aw.is_open(), "")

	print("[app-test] %s (%d failures)" % ["PASSED" if failures == 0 else "FAILED", failures])
	get_tree().quit(failures)


func _tap_world(world_pos: Vector2) -> void:
	var window_pos: Vector2 = get_viewport().get_final_transform() * (main.get_canvas_transform() * world_pos)
	var t := InputEventScreenTouch.new()
	t.position = window_pos
	t.pressed = true
	Input.parse_input_event(t)
	await get_tree().create_timer(0.03).timeout
	var r := InputEventScreenTouch.new()
	r.position = window_pos
	r.pressed = false
	Input.parse_input_event(r)
	await get_tree().process_frame


func _double_tap_world(world_pos: Vector2) -> void:
	await _tap_world(world_pos)
	await get_tree().create_timer(0.08).timeout
	await _tap_world(world_pos)


func _app_check(label: String, ok: bool, detail: String) -> int:
	print("[app-test] %-44s %s %s" % [label, "OK" if ok else "FAIL", detail])
	return int(not ok)
