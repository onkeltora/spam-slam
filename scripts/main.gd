extends Node2D
## Main scene: spawns mails into the inbox queue, reads swipes/keys,
## resolves sorts via GameManager and plays all the world feedback.

const SWIPE_COMMIT_DISTANCE := 90.0    # drag this far = sorted, even while still holding
const SWIPE_RELEASE_DISTANCE := 45.0   # releasing after this distance also sorts
const SWIPE_FLICK_DISTANCE := 28.0     # short but fast flicks count too
const SWIPE_FLICK_SPEED := 1100.0
const DRAG_FOLLOW := 0.6
const DRAG_MAX := 110.0
const TAP_MAX_DISTANCE := 12.0         # finger moved less than this = tap, not swipe
const DOUBLE_TAP_MSEC := 400           # second tap on the same desktop icon within this = open program
const EMPTY_INBOX_SPAWN_BOOST := 2.5   # empty inbox = next mail comes faster
const GAME_OVER_SCREEN_DELAY := 1.2   # fired: CRT power-off, then results
const CRASH_BLUESCREEN_DELAY := 0.75  # inbox overflow: window trail glitch, then bluescreen...
const CRASH_SCREEN_DELAY := 2.6       # ...which stays readable for a moment

@onready var camera: Camera2D = $Camera2D
@onready var pile: InboxPile = %Pile
@onready var cards: Node2D = %Cards
@onready var folder_root: Node2D = %Folders
@onready var fx: Node2D = %FX
@onready var screen_overlay: ScreenOverlay = %ScreenOverlay
@onready var desktop: Node2D = %Desktop
@onready var taskbar: Node2D = %Taskbar
@onready var app_windows: AppWindows = %AppWindows
@onready var overlay: CanvasLayer = %Overlay
@onready var crt: ColorRect = get_node("World/CRT")
@onready var bezel: Node2D = get_node("World/Bezel")

var in_tray_meter: InTrayMeter
var queue: Array[MailData] = []
var front_card: MailPresenter = null
var folders := {}  # MailData.Category -> SortTarget (SortFolder or PaperTray)

var _spawn_timer := 0.0
var _shake := 0.0
var _touch_index := -1
var _touch_start := Vector2.ZERO
var _swipe_done := false
var _last_tap_icon := ""
var _last_tap_msec := 0


func _ready() -> void:
	in_tray_meter = InTrayMeter.new()
	get_node("World").add_child(in_tray_meter)
	_rebuild_targets()
	_apply_era_visuals()

	GameManager.screen_shake.connect(func(intensity: float) -> void: _shake = maxf(_shake, intensity))
	GameManager.baskets_swapped.connect(_on_baskets_swapped)
	GameManager.game_over.connect(_on_game_over)
	GameManager.boost_started.connect(func(_d: float) -> void:
		for folder in folders.values():
			_burst(folder.position, Color("c47a2c"), 18))
	app_windows.window_changed.connect(taskbar.set_app_title)
	overlay.start_requested.connect(_start_run)
	overlay.show_title()

	if OS.is_debug_build() and "--autoplay" in OS.get_cmdline_user_args():
		var bot: Node = load("res://scripts/debug/autoplay.gd").new()
		bot.main = self
		add_child(bot)


func _start_run() -> void:
	for card in cards.get_children():
		card.queue_free()
	front_card = null
	queue.clear()
	pile.reset()
	_apply_era_visuals()  # era may have changed since the last run (bought in the era shop)
	screen_overlay.boot()
	GameManager.start_game()
	_rebuild_targets()
	_spawn_timer = 0.0
	_spawn_mail()


## (Re)builds the 4 sorting targets for the currently active era -- SortFolder (desktop
## icon) if it has a monitor, PaperTray (physical in/out tray) if it doesn't.
func _rebuild_targets() -> void:
	for child in folder_root.get_children():
		child.queue_free()
	folders.clear()
	var has_monitor: bool = EraManager.current().has_monitor
	for dir in GameManager.DEFAULT_LAYOUT:
		var target: SortTarget = SortFolder.new() if has_monitor else PaperTray.new()
		folder_root.add_child(target)
		target.setup(GameManager.DEFAULT_LAYOUT[dir], dir)
		folders[target.category] = target


## Shows/hides the monitor-only chrome for the currently active era. The mail
## presenter/sort-target classes and InboxPile branch on medium/era themselves;
## this only handles whole subsystems that exist or don't exist per era.
func _apply_era_visuals() -> void:
	var has_monitor: bool = EraManager.current().has_monitor
	desktop.visible = has_monitor
	crt.visible = has_monitor
	bezel.visible = has_monitor
	taskbar.visible = has_monitor
	app_windows.visible = has_monitor
	in_tray_meter.visible = not has_monitor
	pile.position = ScreenLayout.card_home()


func _process(delta: float) -> void:
	_update_shake(delta)
	if not GameManager.running:
		return
	if GameManager.spawn_pause <= 0.0:
		_spawn_timer += delta * (EMPTY_INBOX_SPAWN_BOOST if queue.is_empty() else 1.0)
		var interval := GameManager.get_spawn_interval()
		if _spawn_timer >= interval:
			_spawn_timer -= interval
			_spawn_mail()


func _update_shake(delta: float) -> void:
	_shake = move_toward(_shake, 0.0, delta * 45.0)
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake


# --- Inbox queue ---

func _spawn_mail() -> void:
	var mail := GameManager.create_next_mail()
	queue.append(mail)
	if front_card == null:
		mail.pile_drop = 0.0
		_bring_next_to_front(false)
	else:
		pile.set_mails(queue.slice(1))
	GameManager.set_pile_count(queue.size())


func _bring_next_to_front(from_pile: bool) -> void:
	if queue.is_empty():
		front_card = null
		pile.set_mails([])
		return
	var card: MailPresenter = PaperLetterCard.new() if queue[0].medium == MailData.Medium.PAPER else MailCard.new()
	card.z_index = 2
	cards.add_child(card)
	var card_home := ScreenLayout.card_home()
	var start := card_home + (InboxPile.LAYER_OFFSET if from_pile else Vector2(0, -150))
	card.setup(queue[0], start)
	card.scale = Vector2.ONE * (0.97 if from_pile else 0.85)
	if not from_pile:
		card.modulate.a = 0.0
	var duration := GameManager.get_slide_duration()
	var tween := card.create_tween().set_parallel()
	tween.tween_property(card, "base_position", card_home, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "scale", Vector2.ONE, duration)
	tween.tween_property(card, "modulate:a", 1.0, duration * 0.6)
	front_card = card
	pile.set_mails(queue.slice(1))
	if from_pile:
		pile.advance()
	GameManager.mail_presented.emit(queue[0])


# --- Input ---

func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.running:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var dir := _dir_from_key(event.keycode)
		if dir >= 0 or (event.keycode == KEY_ESCAPE and app_windows.is_open()):
			_on_swipe(dir)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_touch_start = event.position
			_swipe_done = false
		elif not event.pressed and event.index == _touch_index:
			var d: Vector2 = event.position - _touch_start
			if not _swipe_done and d.length() >= SWIPE_RELEASE_DISTANCE:
				_on_swipe(_dir_from_vector(d))
			elif not _swipe_done and d.length() <= TAP_MAX_DISTANCE:
				_on_tap(event.position)
			_touch_index = -1
			_set_drag(Vector2.ZERO)
	elif event is InputEventScreenDrag and event.index == _touch_index and not _swipe_done:
		var d: Vector2 = event.position - _touch_start
		var flick: bool = d.length() >= SWIPE_FLICK_DISTANCE and event.velocity.length() >= SWIPE_FLICK_SPEED
		if d.length() >= SWIPE_COMMIT_DISTANCE or flick:
			_swipe_done = true
			_on_swipe(_dir_from_vector(d))
			_set_drag(Vector2.ZERO)
		elif not app_windows.is_open():
			_set_drag(d)


## A swipe (or direction key) first closes an open desktop program, only then it sorts again.
func _on_swipe(dir: int) -> void:
	if app_windows.is_open():
		app_windows.close_window()
	elif dir >= 0:
		_sort_front(dir)


## Taps: close button / program window first, then desktop icons (single = select, double = open).
func _on_tap(screen_pos: Vector2) -> void:
	var world_pos := get_canvas_transform().affine_inverse() * screen_pos
	if app_windows.handle_tap(world_pos):
		return
	var covered := (front_card != null and front_card.covers(world_pos)) or pile.covers(world_pos)
	# No desktop icons to tap in a no-monitor era.
	var icon: String = "" if covered or not EraManager.current().has_monitor else desktop.icon_at(world_pos)
	var now := Time.get_ticks_msec()
	if icon != "" and icon == _last_tap_icon and now - _last_tap_msec <= DOUBLE_TAP_MSEC:
		app_windows.open_app(icon, desktop.icon_rect(icon))
		_last_tap_icon = ""
		return
	desktop.select(icon)
	_last_tap_icon = icon
	_last_tap_msec = now


func _set_drag(d: Vector2) -> void:
	if front_card != null:
		front_card.set_drag((d * DRAG_FOLLOW).limit_length(DRAG_MAX))
	var preview_dir := _dir_from_vector(d) if d.length() > 12.0 else -1
	var amount := clampf(d.length() / SWIPE_COMMIT_DISTANCE, 0.0, 1.0)
	for folder in folders.values():
		folder.set_preview(amount if folder.dir == preview_dir else 0.0)


func _dir_from_vector(v: Vector2) -> int:
	if absf(v.x) > absf(v.y):
		return GameManager.Dir.RIGHT if v.x > 0 else GameManager.Dir.LEFT
	return GameManager.Dir.DOWN if v.y > 0 else GameManager.Dir.UP


func _dir_from_key(keycode: Key) -> int:
	match keycode:
		KEY_UP, KEY_W:
			return GameManager.Dir.UP
		KEY_DOWN, KEY_S:
			return GameManager.Dir.DOWN
		KEY_LEFT, KEY_A:
			return GameManager.Dir.LEFT
		KEY_RIGHT, KEY_D:
			return GameManager.Dir.RIGHT
	return -1


func _dir_of_category(category: MailData.Category) -> int:
	for dir in GameManager.basket_layout:
		if GameManager.basket_layout[dir] == category:
			return dir
	return 0


# --- Sorting & feedback ---

func _sort_front(dir: int) -> void:
	if front_card == null or queue.is_empty():
		return
	var mail: MailData = queue.pop_front()
	var card := front_card
	front_card = null

	var result := GameManager.sort_mail(mail, dir)
	var chosen: SortTarget = folders[result.chosen]
	var card_home := ScreenLayout.card_home()
	card.fly_to(chosen.position)

	if result.correct:
		chosen.gulp()
		_burst(chosen.position, MailData.CATEGORY_COLORS[result.chosen], 14 + GameManager.get_multiplier() * 4)
		var label := "+%d" % result.points
		FloatingText.spawn(fx, chosen.position + Vector2(0, -20), label, Color("fff4d6"), 26 + GameManager.get_multiplier() * 3, 0.7)
		_shake = maxf(_shake, 2.0 + GameManager.get_multiplier())
	else:
		chosen.reject()
		var correct_folder: SortTarget = folders[result.correct_category]
		correct_folder.flash_correct()
		_burst(chosen.position, Color(1, 0.2, 0.15), 22)
		# Wants to sit just above the card, but never overlap the UP tray -- with the
		# 60er's tall letter there's barely a gap between the two, so the tray wins.
		var up_tray_bottom: float = ScreenLayout.folder_slots()[GameManager.Dir.UP].y + 85.0
		var above_y := maxf(card_home.y - card.card_size.y * 0.5 - 25.0, up_tray_bottom)
		FloatingText.spawn(fx, Vector2(card_home.x, above_y), "✗ " + result.reason, Color("ff6a5a"), 24, 1.6, 20.0)

	if GameManager.running:
		GameManager.set_pile_count(queue.size())
		_bring_next_to_front(true)


func _burst(pos: Vector2, color: Color, amount: int) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.z_index = 10
	p.amount = amount
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.6
	p.direction = Vector2.UP
	p.spread = 180.0
	p.initial_velocity_min = 140.0
	p.initial_velocity_max = 380.0
	p.gravity = Vector2(0, 700)
	p.damping_min = 60.0
	p.damping_max = 120.0
	p.scale_amount_min = 4.0
	p.scale_amount_max = 9.0
	p.angular_velocity_min = -400.0
	p.angular_velocity_max = 400.0
	var fade := Gradient.new()
	fade.set_color(0, color.lightened(0.3))
	fade.set_color(1, Color(color, 0.0))
	p.color_ramp = fade
	fx.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


func _on_baskets_swapped(_a: int, _b: int) -> void:
	for folder in folders.values():
		folder.move_to_slot(_dir_of_category(folder.category))
	_shake = maxf(_shake, 10.0)


func _on_game_over(reason: String) -> void:
	_touch_index = -1
	_set_drag(Vector2.ZERO)
	if front_card != null:
		front_card.set_drag(Vector2.ZERO)
	if reason == "pile":
		pile.crash()
		_shake = 14.0
		await get_tree().create_timer(CRASH_BLUESCREEN_DELAY).timeout
		screen_overlay.bluescreen()
		_shake = 8.0
		await get_tree().create_timer(CRASH_SCREEN_DELAY - CRASH_BLUESCREEN_DELAY).timeout
	else:
		screen_overlay.power_off()
		_shake = 18.0
		await get_tree().create_timer(GAME_OVER_SCREEN_DELAY).timeout
	overlay.show_game_over(reason)
