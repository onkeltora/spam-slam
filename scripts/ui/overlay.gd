extends CanvasLayer
## Title screen and game over screen. Any key / tap (re)starts the run.

signal start_requested

const INPUT_DELAY := 0.8  # ignore input right after game over (no accidental restart mid-swipe)

enum Mode { TITLE, GAME_OVER }

@onready var dim: ColorRect = %Dim
@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var score_label: Label = %ScoreLabel
@onready var best_label: Label = %BestLabel
@onready var stats_label: Label = %StatsLabel
@onready var prompt_label: Label = %PromptLabel
@onready var language_button: Button = %LanguageButton

var _mode := Mode.TITLE
var _reason := ""
var _input_cooldown := 0.0
var _time := 0.0


func _ready() -> void:
	language_button.pressed.connect(GameManager.toggle_language)
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
	var is_title := _mode == Mode.TITLE
	score_label.visible = not is_title
	best_label.visible = true
	stats_label.visible = true
	if is_title:
		title_label.text = tr("TITLE_NAME")
		subtitle_label.text = tr("TITLE_HINT") + "\n" + tr("TITLE_HINT2")
		best_label.text = ""
		stats_label.text = tr("GAMEOVER_BEST").format({"v": GameManager.highscore}) if GameManager.highscore > 0 else ""
		prompt_label.text = tr("TITLE_START")
	else:
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


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _input_cooldown > 0.0:
		return
	var start := false
	if event is InputEventKey and event.pressed and not event.echo:
		start = true
	elif event is InputEventScreenTouch and event.pressed:
		# Mouse clicks on the language button also arrive here as emulated touches.
		start = not language_button.get_global_rect().has_point(event.position)
	if start:
		get_viewport().set_input_as_handled()
		visible = false
		start_requested.emit()
