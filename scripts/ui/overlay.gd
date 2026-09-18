class_name Overlay
extends CanvasLayer
## Title screen, game-over screen and the two Budget-Punkte shops in between. Any
## key/tap advances, except taps on the language or buy button. Flow: Title -(tap)->
## game -> Game Over -(tap)-> Shop (desk decor) -(tap)-> Era Shop (era unlocks)
## -(tap)-> next game. Both shops only appear right after a run (GDD Abschnitt 8's
## "Run -> Budget-Punkte -> Meta-Screen -> ggf. Kauf -> nächster Run"). Buying an era
## makes it active immediately (EraManager.unlock_next() also selects it) -- there's
## no era-switcher UI yet to go back to an earlier one.

signal start_requested

const INPUT_DELAY := 0.8  # ignore input right after game over (no accidental restart mid-swipe)

enum Mode { TITLE, GAME_OVER, SHOP, ERA_SHOP }

@onready var dim: ColorRect = %Dim
@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var score_label: Label = %ScoreLabel
@onready var best_label: Label = %BestLabel
@onready var stats_label: Label = %StatsLabel
@onready var prompt_label: Label = %PromptLabel
@onready var language_button: Button = %LanguageButton
@onready var buy_button: Button = %BuyButton

var _mode := Mode.TITLE
var _reason := ""
var _input_cooldown := 0.0
var _time := 0.0


func _ready() -> void:
	language_button.pressed.connect(GameManager.toggle_language)
	buy_button.pressed.connect(_on_buy_pressed)
	GameManager.language_changed.connect(_refresh_texts)


func show_title() -> void:
	_mode = Mode.TITLE
	_open()


func show_game_over(reason: String) -> void:
	_mode = Mode.GAME_OVER
	_reason = reason
	_open()


func _open() -> void:
	visible = true
	_input_cooldown = INPUT_DELAY if _mode == Mode.GAME_OVER else 0.2
	_refresh_texts()
	dim.modulate.a = 0.0
	create_tween().tween_property(dim, "modulate:a", 1.0, 0.3)


func _refresh_texts() -> void:
	language_button.text = tr("BTN_LANGUAGE")
	score_label.visible = _mode == Mode.GAME_OVER
	best_label.visible = _mode == Mode.TITLE or _mode == Mode.GAME_OVER
	stats_label.visible = true
	var next := MetaProgress.next_item()
	var next_era := EraManager.next_locked_era()
	buy_button.visible = (_mode == Mode.SHOP and not next.is_empty()) \
			or (_mode == Mode.ERA_SHOP and not next_era.is_empty())
	match _mode:
		Mode.TITLE:
			title_label.text = tr("TITLE_NAME")
			subtitle_label.text = tr("TITLE_HINT") + "\n" + tr("TITLE_HINT2")
			best_label.text = ""
			stats_label.text = tr("GAMEOVER_BEST").format({"v": GameManager.highscore}) if GameManager.highscore > 0 else ""
			prompt_label.text = tr("TITLE_START")
		Mode.GAME_OVER:
			title_label.text = tr("GAMEOVER_TITLE")
			subtitle_label.text = tr("GAMEOVER_PILE") if _reason == "pile" else tr("GAMEOVER_LIVES")
			score_label.text = tr("GAMEOVER_SCORE").format({"v": GameManager.score})
			if GameManager.is_new_highscore:
				best_label.text = "★ " + tr("GAMEOVER_NEW_BEST") + " ★"
			else:
				best_label.text = tr("GAMEOVER_BEST").format({"v": GameManager.highscore})
			stats_label.text = tr("GAMEOVER_STATS").format({
				"sorted": GameManager.sorted_count,
				"acc": GameManager.get_accuracy(),
				"combo": GameManager.max_combo,
				"time": roundi(GameManager.elapsed),
			})
			prompt_label.text = tr("GAMEOVER_RESTART")
		Mode.SHOP:
			title_label.text = tr("SHOP_TITLE")
			if next.is_empty():
				subtitle_label.text = tr("SHOP_ALL_OWNED")
				stats_label.text = tr("SHOP_BUDGET").format({"v": MetaProgress.budget})
			else:
				subtitle_label.text = tr(next.name_key)
				stats_label.text = tr("SHOP_PROGRESS").format({"have": MetaProgress.budget, "cost": next.cost})
				buy_button.text = tr("SHOP_BUY")
				buy_button.disabled = not MetaProgress.can_afford_next()
			prompt_label.text = tr("SHOP_CONTINUE")
		Mode.ERA_SHOP:
			title_label.text = tr("ERA_SHOP_TITLE")
			if next_era.is_empty():
				subtitle_label.text = tr("ERA_SHOP_ALL_UNLOCKED")
				stats_label.text = tr("SHOP_BUDGET").format({"v": MetaProgress.budget})
			else:
				subtitle_label.text = tr(next_era.name_key)
				stats_label.text = tr("SHOP_PROGRESS").format({"have": MetaProgress.budget, "cost": next_era.unlock_cost})
				buy_button.text = tr("SHOP_BUY")
				buy_button.disabled = not EraManager.can_afford_next()
			prompt_label.text = tr("SHOP_CONTINUE")


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	_input_cooldown = maxf(_input_cooldown - delta, 0.0)
	prompt_label.modulate.a = 0.0 if _input_cooldown > 0.0 else 0.55 + 0.45 * sin(_time * 5.0)
	if _mode == Mode.GAME_OVER and GameManager.is_new_highscore:
		best_label.modulate = Color.WHITE.lerp(Color("ffd65a"), 0.5 + 0.5 * sin(_time * 8.0))
	else:
		best_label.modulate = Color.WHITE


func _on_buy_pressed() -> void:
	var bought := MetaProgress.buy_next() if _mode == Mode.SHOP else EraManager.unlock_next()
	if bought:
		_refresh_texts()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _input_cooldown > 0.0:
		return
	var advance := false
	if event is InputEventKey and event.pressed and not event.echo:
		advance = true
	elif event is InputEventScreenTouch and event.pressed:
		# Mouse clicks on the language/buy buttons also arrive here as emulated touches.
		var on_button := language_button.get_global_rect().has_point(event.position)
		on_button = on_button or (buy_button.visible and buy_button.get_global_rect().has_point(event.position))
		advance = not on_button
	if not advance:
		return
	get_viewport().set_input_as_handled()
	match _mode:
		Mode.GAME_OVER:
			_mode = Mode.SHOP
			_input_cooldown = 0.3
			_refresh_texts()
		Mode.SHOP:
			_mode = Mode.ERA_SHOP
			_input_cooldown = 0.3
			_refresh_texts()
		_:
			visible = false
			start_requested.emit()
