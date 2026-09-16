extends Node
## Global game state (Autoload "GameManager").
## Owns score, combo, lives, active rule, basket layout, tempo, inbox pile,
## coffee boost and boss challenges. Everything else listens to its signals.

signal game_started
signal game_over(reason: String)  # "lives" | "pile"
signal mail_sorted(result: Dictionary)
signal score_changed(score: int)
signal combo_changed(combo: int, multiplier: int)
signal lives_changed(lives: int, delta: int)
signal pile_changed(count: int, max_count: int)
signal coffee_changed(fill: float)
signal boost_started(duration: float)
signal boost_ended
signal rule_changed(rule: SortRule)
signal baskets_swapped(dir_a: int, dir_b: int)
signal boss_challenge_started(goal: int, rewards_life: bool)
signal boss_challenge_progress(progress: int, goal: int)
signal boss_challenge_finished(success: bool)
signal screen_shake(intensity: float)
signal language_changed

enum Dir { UP, DOWN, LEFT, RIGHT }

# --- Balancing (alles an einem Ort zum Schrauben) ---
const START_LIVES := 3
const MAX_LIVES := 5
const PILE_MAX := 12                   # this many unsorted mails = collapse
const BASE_POINTS := 100
const COMBO_PER_MULTIPLIER := 5        # every 5 streak = +1 multiplier
const MAX_MULTIPLIER := 5
const SPAWN_INTERVAL_START := 2.0      # seconds between mails at t=0
const SPAWN_INTERVAL_RAMPED := 0.85    # ...after TEMPO_RAMP_TIME
const SPAWN_INTERVAL_FLOOR := 0.5      # ...after TEMPO_RAMP_TIME + OVERTIME_RAMP_TIME
const TEMPO_RAMP_TIME := 100.0
const OVERTIME_RAMP_TIME := 120.0
const SLIDE_DURATION_START := 0.24     # next mail sliding to the front
const SLIDE_DURATION_END := 0.11
const COFFEE_STREAK := 10              # correct in a row to fill the mug...
const COFFEE_STREAK_GROWTH := 5        # ...+5 more for every boost already earned this run
const BOOST_DURATION := 5.0
const BOOST_SPAWN_FACTOR := 1.7        # spawn interval multiplier while boosted
const FIRST_RULE_AFTER := 5            # sorted mails before the first special rule
const RULE_CHANGE_MIN := 8
const RULE_CHANGE_MAX := 10
const REORG_EVERY := 4                 # every Nth rule event swaps two baskets instead
const RULE_ANNOUNCE_PAUSE := 1.3       # no new mails while the new rule is announced
const BOSS_EVERY_MIN := 20
const BOSS_EVERY_MAX := 30
const BOSS_GOAL := 5
const BOSS_SCORE_REWARD := 2000        # instead of a life when already at MAX_LIVES

const DEFAULT_LAYOUT := {
	Dir.UP: MailData.Category.IMPORTANT,
	Dir.RIGHT: MailData.Category.SPAM,
	Dir.LEFT: MailData.Category.NEWSLETTER,
	Dir.DOWN: MailData.Category.PHISHING,
}
const SAVE_PATH := "user://save.cfg"
const LANGUAGES := ["en", "de"]

var running := false
var score := 0
var combo := 0
var max_combo := 0
var lives := START_LIVES
var elapsed := 0.0
var pile_count := 0
var coffee := 0.0
var boost_time := 0.0
var boosts_earned := 0
var spawn_pause := 0.0
var active_rule: SortRule = null
var basket_layout: Dictionary = DEFAULT_LAYOUT.duplicate()  # Dir -> Category
var sorted_count := 0
var correct_count := 0
var highscore := 0
var is_new_highscore := false
var persist_highscore := true  # the autoplay bot turns this off
var boss_challenge_active := false
var boss_progress := 0

var _rule_pool: Array[SortRule] = []
var _mails_until_rule_event := FIRST_RULE_AFTER
var _rule_events := 0
var _mails_until_boss := BOSS_EVERY_MIN
var _generator := MailGenerator.new()


func _ready() -> void:
	randomize()
	_load_save()


func _process(delta: float) -> void:
	if not running:
		return
	elapsed += delta
	spawn_pause = maxf(spawn_pause - delta, 0.0)
	if boost_time > 0.0:
		boost_time -= delta
		coffee = maxf(boost_time / BOOST_DURATION, 0.0)
		coffee_changed.emit(coffee)
		if boost_time <= 0.0:
			boost_time = 0.0
			coffee = 0.0
			boost_ended.emit()


func start_game() -> void:
	score = 0
	combo = 0
	max_combo = 0
	lives = START_LIVES
	elapsed = 0.0
	pile_count = 0
	coffee = 0.0
	boost_time = 0.0
	boosts_earned = 0
	spawn_pause = 0.0
	active_rule = null
	basket_layout = DEFAULT_LAYOUT.duplicate()
	sorted_count = 0
	correct_count = 0
	is_new_highscore = false
	boss_challenge_active = false
	boss_progress = 0
	_rule_pool = RulePool.create()
	_mails_until_rule_event = FIRST_RULE_AFTER
	_rule_events = 0
	_mails_until_boss = randi_range(BOSS_EVERY_MIN, BOSS_EVERY_MAX)
	running = true

	score_changed.emit(score)
	combo_changed.emit(combo, get_multiplier())
	lives_changed.emit(lives, 0)
	pile_changed.emit(pile_count, PILE_MAX)
	coffee_changed.emit(coffee)
	rule_changed.emit(null)
	game_started.emit()


# --- Tempo ---

## 0..1 over the main ramp, used for everything that should speed up.
func get_tempo() -> float:
	return clampf(elapsed / TEMPO_RAMP_TIME, 0.0, 1.0)


func get_spawn_interval() -> float:
	var interval: float
	if elapsed <= TEMPO_RAMP_TIME:
		interval = lerpf(SPAWN_INTERVAL_START, SPAWN_INTERVAL_RAMPED, get_tempo())
	else:
		var t := clampf((elapsed - TEMPO_RAMP_TIME) / OVERTIME_RAMP_TIME, 0.0, 1.0)
		interval = lerpf(SPAWN_INTERVAL_RAMPED, SPAWN_INTERVAL_FLOOR, t)
	if is_boosting():
		interval *= BOOST_SPAWN_FACTOR
	return interval


func get_slide_duration() -> float:
	return lerpf(SLIDE_DURATION_START, SLIDE_DURATION_END, get_tempo())


func is_boosting() -> bool:
	return boost_time > 0.0


func get_multiplier() -> int:
	return mini(1 + combo / COMBO_PER_MULTIPLIER, MAX_MULTIPLIER)


# --- Mails ---

func create_next_mail() -> MailData:
	_mails_until_boss -= 1
	if _mails_until_boss <= 0 and not boss_challenge_active:
		_mails_until_boss = randi_range(BOSS_EVERY_MIN, BOSS_EVERY_MAX)
		return _generator.generate_boss()
	return _generator.generate(active_rule)


func get_correct_category(mail: MailData) -> MailData.Category:
	if mail.is_boss:
		return MailData.Category.IMPORTANT
	if active_rule != null and active_rule.matches(mail):
		return active_rule.target
	return mail.base_category()


## Short explanation shown when the player got it wrong.
func get_reason_text(mail: MailData) -> String:
	var category := get_correct_category(mail)
	if mail.is_boss:
		return tr("BASE_BOSS") + "  →  " + tr(MailData.CATEGORY_KEYS[category])
	if active_rule != null and active_rule.matches(mail):
		return active_rule.get_text()
	return tr(MailData.BASE_RULE_KEYS[category]) + "  →  " + tr(MailData.CATEGORY_KEYS[category])


func get_category_for_dir(dir: Dir) -> MailData.Category:
	return basket_layout[dir]


## Resolves a swipe. Returns {correct, chosen, correct_category, points, reason}.
func sort_mail(mail: MailData, dir: Dir) -> Dictionary:
	var chosen: MailData.Category = basket_layout[dir]
	var correct_category := get_correct_category(mail)
	var correct := chosen == correct_category
	var result := {
		"mail": mail,
		"correct": correct,
		"chosen": chosen,
		"correct_category": correct_category,
		"points": 0,
		"reason": get_reason_text(mail),
	}
	sorted_count += 1

	if correct:
		correct_count += 1
		combo += 1
		max_combo = maxi(max_combo, combo)
		var points := BASE_POINTS * get_multiplier()
		score += points
		result.points = points
		if not is_boosting():
			coffee = minf(coffee + 1.0 / (COFFEE_STREAK + COFFEE_STREAK_GROWTH * boosts_earned), 1.0)
			coffee_changed.emit(coffee)
			if coffee >= 0.999:
				boosts_earned += 1
				boost_time = BOOST_DURATION
				boost_started.emit(BOOST_DURATION)
		if mail.is_boss:
			_start_boss_challenge()
		elif boss_challenge_active:
			boss_progress += 1
			boss_challenge_progress.emit(boss_progress, BOSS_GOAL)
			if boss_progress >= BOSS_GOAL:
				_finish_boss_challenge(true)
		score_changed.emit(score)
	else:
		combo = 0
		lives -= 1
		if not is_boosting():
			coffee = 0.0
			coffee_changed.emit(coffee)
		screen_shake.emit(14.0)
		lives_changed.emit(lives, -1)
		if boss_challenge_active:
			_finish_boss_challenge(false)

	combo_changed.emit(combo, get_multiplier())
	mail_sorted.emit(result)

	if lives <= 0:
		_end_game("lives")
	else:
		_mails_until_rule_event -= 1
		if _mails_until_rule_event <= 0:
			_advance_rule()
	return result


func set_pile_count(count: int) -> void:
	pile_count = count
	pile_changed.emit(count, PILE_MAX)
	if running and count >= PILE_MAX:
		_end_game("pile")


# --- Rules ---

func _advance_rule() -> void:
	_rule_events += 1
	_mails_until_rule_event = randi_range(RULE_CHANGE_MIN, RULE_CHANGE_MAX)
	spawn_pause = RULE_ANNOUNCE_PAUSE
	if active_rule != null and _rule_events % REORG_EVERY == 0:
		_reorg_baskets()
		return
	var candidates := _rule_pool.filter(func(r: SortRule) -> bool: return r != active_rule)
	active_rule = candidates.pick_random()
	rule_changed.emit(active_rule)


## Rug-pull: IT swaps two baskets. The rule stays, muscle memory breaks.
func _reorg_baskets() -> void:
	var dirs: Array = Dir.values()
	dirs.shuffle()
	var a: Dir = dirs[0]
	var b: Dir = dirs[1]
	var tmp: MailData.Category = basket_layout[a]
	basket_layout[a] = basket_layout[b]
	basket_layout[b] = tmp
	baskets_swapped.emit(a, b)


# --- Boss challenge ---

func _start_boss_challenge() -> void:
	boss_challenge_active = true
	boss_progress = 0
	boss_challenge_started.emit(BOSS_GOAL, lives < MAX_LIVES)


func _finish_boss_challenge(success: bool) -> void:
	boss_challenge_active = false
	if success:
		if lives < MAX_LIVES:
			lives += 1
			lives_changed.emit(lives, 1)
		else:
			score += BOSS_SCORE_REWARD
			score_changed.emit(score)
	boss_challenge_finished.emit(success)


# --- Game over & persistence ---

func _end_game(reason: String) -> void:
	if not running:
		return
	running = false
	boost_time = 0.0
	if score > highscore and persist_highscore:
		highscore = score
		is_new_highscore = true
		_save()
	game_over.emit.call_deferred(reason)


func get_accuracy() -> int:
	return 0 if sorted_count == 0 else roundi(100.0 * correct_count / sorted_count)


func toggle_language() -> void:
	var index := LANGUAGES.find(TranslationServer.get_locale().substr(0, 2))
	TranslationServer.set_locale(LANGUAGES[(index + 1) % LANGUAGES.size()])
	_save()
	language_changed.emit()


func _load_save() -> void:
	var cfg := ConfigFile.new()
	var language := ""
	if cfg.load(SAVE_PATH) == OK:
		highscore = cfg.get_value("stats", "highscore", 0)
		language = cfg.get_value("settings", "language", "")
	if language == "":
		language = "de" if OS.get_locale_language() == "de" else "en"
	TranslationServer.set_locale(language)


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("stats", "highscore", highscore)
	cfg.set_value("settings", "language", TranslationServer.get_locale().substr(0, 2))
	cfg.save(SAVE_PATH)
