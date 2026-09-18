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
##   godot --path . -- --autoplay --shop-test [--shots=DIR]   (MetaProgress + shop screen, real taps)
##   godot --path . -- --autoplay --era-test [--shots=DIR]     (EraManager: 60er paper era + 90er retrofit)
##   godot --path . -- --autoplay --era=sixties [--shots=DIR]  (dev override: force-unlock+select an era)

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
	MetaProgress.persist = false    # never touch the real progress.cfg from the bot
	EraManager.persist = false      # never touch the real era.cfg from the bot
	DisplayManager.persist = false  # never touch the real display.cfg from the bot
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--think="):
			think = arg.get_slice("=", 1).to_float()
		elif arg.begins_with("--accuracy="):
			accuracy = arg.get_slice("=", 1).to_float()
		elif arg.begins_with("--lang="):
			TranslationServer.set_locale(arg.get_slice("=", 1))  # not saved
		elif arg.begins_with("--era="):
			var era_id := arg.get_slice("=", 1)
			if era_id not in EraManager.unlocked:
				EraManager.unlocked.append(era_id)  # dev override, bypasses the era shop cost
			EraManager.select(era_id)
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
	if "--shop-test" in OS.get_cmdline_user_args():
		_shop_test()
		return
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
	if "--era-test" in OS.get_cmdline_user_args():
		_era_test()
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
			var g := generator.generate(rule, EraManager.current())
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
	await _tap_at(get_viewport().get_final_transform() * (main.get_canvas_transform() * world_pos))


## For UI in a separate CanvasLayer (Overlay), which isn't behind main's Camera2D/canvas transform.
func _tap_screen(viewport_pos: Vector2) -> void:
	await _tap_at(get_viewport().get_final_transform() * viewport_pos)


func _tap_at(window_pos: Vector2) -> void:
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


# --- Shop test: Budget-Punkte accrual + the sequential shop, via a real run and real taps ---

func _shop_test() -> void:
	set_process(false)
	var failures := 0
	var overlay := main.overlay as Overlay
	var desk: Node2D = main.get_node("Desk")

	# Start from a clean slate regardless of what the real save file (or an earlier
	# test in this process) contains — MetaProgress.persist is already off (see _ready()).
	MetaProgress.budget = 0
	MetaProgress.owned.clear()

	GameManager.start_game()
	GameManager.score = MetaProgress.ITEMS[0].cost * 10  # exact price of item 1, see SCORE_TO_BUDGET
	GameManager._end_game("lives")
	await get_tree().process_frame
	failures += _shop_check("run credits Budget-Punkte proportional to score",
			MetaProgress.budget == MetaProgress.ITEMS[0].cost,
			"%d budget" % MetaProgress.budget)

	# Save/load round-trip through a scratch file, so the real progress.cfg is never touched.
	var scratch_path := "user://shop_test_scratch.cfg"
	MetaProgress.save_path = scratch_path
	MetaProgress.persist = true
	MetaProgress.owned = ["plant"]
	MetaProgress._save()
	var raw := ConfigFile.new()
	raw.load(scratch_path)
	failures += _shop_check("save writes budget and owned items to disk",
			raw.get_value("progress", "budget", -1) == MetaProgress.budget
			and raw.get_value("progress", "owned", []) == MetaProgress.owned, "")
	MetaProgress.budget = 0
	MetaProgress.owned.clear()
	MetaProgress._load()
	failures += _shop_check("load restores budget and owned items from disk",
			MetaProgress.budget == MetaProgress.ITEMS[0].cost and MetaProgress.owned == ["plant"],
			"%d budget, owned=%s" % [MetaProgress.budget, MetaProgress.owned])
	DirAccess.remove_absolute(scratch_path)
	MetaProgress.save_path = MetaProgress.SAVE_PATH
	MetaProgress.persist = false
	MetaProgress.owned.clear()  # back to a clean slate for the rest of the test

	await get_tree().create_timer(2.2).timeout  # GAME_OVER_SCREEN_DELAY + INPUT_DELAY
	failures += _shop_check("game over screen shows first, not the shop", overlay._mode == Overlay.Mode.GAME_OVER, "")

	await _tap_screen(Vector2(50, 50))  # anywhere but the buttons
	failures += _shop_check("tap after game-over stats opens the shop", overlay._mode == Overlay.Mode.SHOP, "")
	failures += _shop_check("shop shows the next item and its price",
			overlay.subtitle_label.text == tr(MetaProgress.ITEMS[0].name_key)
			and overlay.stats_label.text == tr("SHOP_PROGRESS").format({"have": MetaProgress.budget, "cost": MetaProgress.ITEMS[0].cost}), "")
	failures += _shop_check("buy button is enabled (exact price met)", overlay.buy_button.visible and not overlay.buy_button.disabled, "")

	await _tap_screen(overlay.buy_button.get_global_rect().get_center())
	failures += _shop_check("tapping buy purchases the item", MetaProgress.is_owned("plant") and MetaProgress.budget == 0, "")
	failures += _shop_check("shop stays open after buying (no accidental restart)", overlay._mode == Overlay.Mode.SHOP, "")
	failures += _shop_check("next item advances to the second one",
			MetaProgress.next_item().id == MetaProgress.ITEMS[1].id, "")
	failures += _shop_check("buy button disables once unaffordable", overlay.buy_button.disabled, "")

	await get_tree().create_timer(0.55).timeout  # let the desk pop-in tween finish
	failures += _shop_check("the bought item actually appears on the desk", desk.get("_plant_appear") > 0.9, "%.2f" % desk.get("_plant_appear"))
	if shots_dir != "":
		await _shot("shop_after_purchase")

	await _tap_screen(Vector2(50, 50))
	failures += _shop_check("tap on the desk shop (not the buy button) opens the era shop", overlay._mode == Overlay.Mode.ERA_SHOP, "")
	failures += _shop_check("era shop shows the next era and its price",
			overlay.subtitle_label.text == tr(EraManager.ERAS[1].name_key)
			and overlay.stats_label.text == tr("SHOP_PROGRESS").format({"have": MetaProgress.budget, "cost": EraManager.ERAS[1].unlock_cost}), "")
	failures += _shop_check("era buy button disabled (not enough budget yet)", overlay.buy_button.visible and overlay.buy_button.disabled, "")

	await get_tree().create_timer(0.35).timeout  # let the SHOP->ERA_SHOP input cooldown expire
	await _tap_screen(Vector2(50, 50))
	await get_tree().process_frame
	failures += _shop_check("tap on the era shop (unaffordable, not the buy button) starts the next run", GameManager.running, "")
	failures += _shop_check("era stays on nineties while unaffordable", EraManager.current_id == "nineties", "")
	if shots_dir != "":
		await get_tree().create_timer(0.3).timeout
		await _shot("desk_during_gameplay_with_plant")

	# Buy the second (last) desk item for real too, then check the "nothing left" state.
	GameManager.score = 999999
	GameManager._end_game("lives")
	await get_tree().create_timer(2.2).timeout
	await _tap_screen(Vector2(50, 50))
	await _tap_screen(overlay.buy_button.get_global_rect().get_center())
	failures += _shop_check("second real purchase also works", MetaProgress.is_owned("lamp"), "")
	await get_tree().create_timer(0.55).timeout
	failures += _shop_check("second bought item appears on the desk too", desk.get("_lamp_appear") > 0.9, "%.2f" % desk.get("_lamp_appear"))
	if shots_dir != "":
		await _shot("shop_both_items_on_desk")

	overlay._refresh_texts()
	failures += _shop_check("shop says everything is furnished once all items are owned",
			not overlay.buy_button.visible and overlay.subtitle_label.text == tr("SHOP_ALL_OWNED"), "")
	if shots_dir != "":
		await _shot("shop_all_owned")

	await _tap_screen(Vector2(50, 50))
	failures += _shop_check("tap on the (all-owned) desk shop opens the era shop", overlay._mode == Overlay.Mode.ERA_SHOP, "")

	# Now give enough budget and actually unlock the era: buy -> active immediately.
	MetaProgress.budget = EraManager.ERAS[1].unlock_cost
	overlay._refresh_texts()
	failures += _shop_check("era buy button enabled once affordable", overlay.buy_button.visible and not overlay.buy_button.disabled, "")
	await _tap_screen(overlay.buy_button.get_global_rect().get_center())
	failures += _shop_check("buying the era unlocks and activates it immediately",
			EraManager.is_unlocked("sixties") and EraManager.current_id == "sixties", "")
	failures += _shop_check("era shop says everything is unlocked once bought",
			not overlay.buy_button.visible and overlay.subtitle_label.text == tr("ERA_SHOP_ALL_UNLOCKED"), "")

	await get_tree().create_timer(0.35).timeout  # let the SHOP->ERA_SHOP input cooldown expire
	await _tap_screen(Vector2(50, 50))
	await get_tree().process_frame
	failures += _shop_check("tap on the fully-unlocked era shop starts the next run", GameManager.running, "")

	print("[shop-test] %s (%d failures)" % ["PASSED" if failures == 0 else "FAILED", failures])
	get_tree().quit(failures)


func _shop_check(label: String, ok: bool, detail: String) -> int:
	print("[shop-test] %-56s %s %s" % [label, "OK" if ok else "FAIL", detail])
	return int(not ok)


# --- Era test: 60er paper era end-to-end, then back to 90er, no half-forgotten monitor bits ---

func _era_test() -> void:
	set_process(false)
	var failures := 0

	if "sixties" not in EraManager.unlocked:
		EraManager.unlocked.append("sixties")
	EraManager.select("sixties")
	_start()
	await get_tree().create_timer(0.3).timeout

	failures += _era_check("monitor chrome hidden in the 60er era",
			not main.desktop.visible and not main.taskbar.visible and not main.app_windows.visible
			and not main.crt.visible and not main.bezel.visible, "")
	failures += _era_check("physical inbox meter shown instead", main.in_tray_meter.visible, "")
	failures += _era_check("front card is a paper letter", main.front_card is PaperLetterCard, "")
	failures += _era_check("sort targets are paper trays", main.folders.values().all(func(t: SortTarget) -> bool: return t is PaperTray), "")

	# A double-tap where a 90er desktop icon would be must never open a program.
	await _double_tap_world(Vector2(274, 72))
	failures += _era_check("desktop icons unreachable, no program ever opens", not main.app_windows.is_open(), "")

	var digital_leak := 0
	var wrong_medium := 0
	for i in 60:
		var mail := GameManager.create_next_mail()
		if mail.medium != MailData.Medium.PAPER:
			wrong_medium += 1
		if mail.attachment_ext != "" or mail.has_link or mail.digits_in_address or mail.biz_domain or mail.smiley_count > 0:
			digital_leak += 1
	failures += _era_check("generated mails are all PAPER medium", wrong_medium == 0, "%d wrong" % wrong_medium)
	failures += _era_check("no digital-only noise leaks into paper mails", digital_leak == 0, "%d leaked" % digital_leak)

	var bad_conditions := 0
	var agnostic := SortRule.medium_agnostic_conditions()
	for i in 20:
		GameManager._advance_rule()
		if GameManager.active_rule != null and GameManager.active_rule.condition not in agnostic:
			bad_conditions += 1
	failures += _era_check("60er rule pool only offers medium-agnostic conditions", bad_conditions == 0, "%d digital-only" % bad_conditions)

	if shots_dir != "":
		await _shot("era_sixties")

	# Pile overflow: the paper-crash cue, not the bluescreen.
	GameManager.set_pile_count(GameManager.PILE_MAX)
	await get_tree().create_timer(main.CRASH_BLUESCREEN_DELAY + 0.2).timeout  # game_over is deferred, then main waits before bluescreen()
	failures += _era_check("pile overflow still ends the run", not GameManager.running, "")
	failures += _era_check("crash cue is in the BSOD state (paper-crash branch draws it, has_monitor=false)",
			main.screen_overlay._state == ScreenOverlay.State.BSOD and not EraManager.current().has_monitor, "")

	await get_tree().create_timer(GameManager.START_LIVES + 3.0).timeout  # let the game-over/shop flow settle

	# Back to the 90er retrofit -- prove the swap is runtime-reversible, not a one-off.
	EraManager.select("nineties")
	_start()
	await get_tree().create_timer(0.3).timeout
	failures += _era_check("monitor chrome back for the 90er era",
			main.desktop.visible and main.taskbar.visible and main.app_windows.visible
			and main.crt.visible and main.bezel.visible, "")
	failures += _era_check("physical inbox meter hidden again", not main.in_tray_meter.visible, "")
	failures += _era_check("front card is back to a digital mail window", main.front_card is MailCard, "")
	failures += _era_check("sort targets are back to desktop folders", main.folders.values().all(func(t: SortTarget) -> bool: return t is SortFolder), "")

	print("[era-test] %s (%d failures)" % ["PASSED" if failures == 0 else "FAILED", failures])
	get_tree().quit(failures)


func _era_check(label: String, ok: bool, detail: String) -> int:
	print("[era-test] %-70s %s %s" % [label, "OK" if ok else "FAIL", detail])
	return int(not ok)
