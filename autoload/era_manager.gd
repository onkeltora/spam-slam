extends Node
## Persistent era progression (Autoload "EraManager").
## Owns which historical eras are unlocked and which one is currently active for the
## next run. Bought with the same Budget-Punkte as MetaProgress's desk shop, but kept
## as its own system because eras change generation/rules/visuals, not just desk decor
## (MetaProgress explicitly scopes itself to cosmetics only).
##
## Buying an era immediately makes it the active one (unlock_next() also selects it) --
## there's no era-switcher UI yet to go back to an earlier unlocked era, only
## select()/is_unlocked() for that later. Note this isn't quite the GDD's strict
## forward-only chronology: the MVP already defaults to the 90er look, and 60er is
## being added as an earlier era rather than a step forward from it.
##
## Add an era = one more entry in ERAS + an ERA_* key in strings.csv + whatever new
## visual classes it needs (see scripts/world/paper_letter_card.gd etc. for the 60er).

signal era_changed(era: Dictionary)
signal era_unlocked(era_id: String)

const SAVE_PATH := "user://era.cfg"

## Ordered; unlock_cost 0 = free/starting era. `id` must stay stable across saves.
## allowed_conditions is a tag resolved by get_allowed_conditions(), not a literal
## Condition array -- SortRule.medium_agnostic_conditions() can't be called inside a
## const initializer, and this keeps ERAS a plain data table either way.
const CONDITIONS_ALL := "all"
const CONDITIONS_MEDIUM_AGNOSTIC := "medium_agnostic"

const ERAS: Array[Dictionary] = [
	{
		"id": "nineties",
		"name_key": "ERA_NINETIES",
		"unlock_cost": 0,
		"paper_ratio": 0.0,
		"has_monitor": true,
		"allowed_conditions": CONDITIONS_ALL,
		"spawn_interval_scale": 1.0,
		"rule_change_scale": 1.0,
	},
	{
		"id": "sixties",
		"name_key": "ERA_SIXTIES",
		"unlock_cost": 1500,
		"paper_ratio": 1.0,
		"has_monitor": false,
		"allowed_conditions": CONDITIONS_MEDIUM_AGNOSTIC,
		"spawn_interval_scale": 1.6,
		"rule_change_scale": 1.4,
	},
]
const DEFAULT_ERA_ID := "nineties"

var unlocked: Array[String] = [DEFAULT_ERA_ID]
var current_id: String = DEFAULT_ERA_ID
var persist := true  # the autoplay bot turns this off, same pattern as MetaProgress.persist

## Overridable so tests can round-trip through a scratch file instead of the real one.
var save_path := SAVE_PATH


func _ready() -> void:
	_load()


## The era definition dictionary in effect for the run about to start.
func current() -> Dictionary:
	return get_era(current_id)


func get_era(id: String) -> Dictionary:
	for era in ERAS:
		if era.id == id:
			return era
	return ERAS[0]


func is_unlocked(id: String) -> bool:
	return id in unlocked


## The next not-yet-unlocked era in ERAS order, or {} once everything is unlocked.
func next_locked_era() -> Dictionary:
	for era in ERAS:
		if not is_unlocked(era.id):
			return era
	return {}


## Resolves the current era's allowed_conditions tag into an actual Condition array
## for RulePool.create(). Empty array means "unfiltered".
func get_allowed_conditions() -> Array[SortRule.Condition]:
	match current().allowed_conditions:
		CONDITIONS_MEDIUM_AGNOSTIC:
			return SortRule.medium_agnostic_conditions()
		_:
			return [] as Array[SortRule.Condition]


func can_afford_next() -> bool:
	var era := next_locked_era()
	return not era.is_empty() and MetaProgress.budget >= era.unlock_cost


## Unlocks the next era if affordable and makes it the active one. Returns whether a
## purchase happened.
func unlock_next() -> bool:
	var era := next_locked_era()
	if era.is_empty() or not MetaProgress.spend(era.unlock_cost):
		return false
	unlocked.append(era.id)
	current_id = era.id
	if persist:
		_save()
	era_unlocked.emit(era.id)
	era_changed.emit(current())
	return true


## Switches the active era for the next run started. Only among already-unlocked eras.
func select(id: String) -> bool:
	if not is_unlocked(id) or id == current_id:
		return false
	current_id = id
	if persist:
		_save()
	era_changed.emit(current())
	return true


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		return
	current_id = cfg.get_value("era", "current_id", DEFAULT_ERA_ID)
	unlocked.clear()
	for id in cfg.get_value("era", "unlocked", [DEFAULT_ERA_ID]):
		unlocked.append(id)
	if DEFAULT_ERA_ID not in unlocked:
		unlocked.append(DEFAULT_ERA_ID)


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("era", "current_id", current_id)
	cfg.set_value("era", "unlocked", unlocked)
	cfg.save(save_path)
