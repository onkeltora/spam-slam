extends Node
## Persistent meta-progression (Autoload "MetaProgress").
## Owns Budget-Punkte (soft currency, credited from every run's score) and the
## sequential desk-decor shop bought with them ("Schreibtisch als Fortschrittsbalken",
## GDD Abschnitt 9). Independent of GameManager's run-scoped state, own save file.
##
## Backbone-first scope: only cosmetic items so far, no gameplay-affecting purchases
## yet (e.g. auto-filter slots) and no shop UI polish beyond a plain overlay screen.
## Add an item = one more entry in ITEMS + a SHOP_ITEM_* key in strings.csv + a
## _draw_xxx() case in desk.gd's item drawing.

signal budget_changed(total: int)
signal item_purchased(item_id: String)

const SAVE_PATH := "user://progress.cfg"
## How many Budget-Punkte one Score point is worth. Placeholder conversion (GDD
## Abschnitt 8 leaves the factor open); tuned so a single average run affords the
## first item. Revisit once there are enough items for a real economy.
const SCORE_TO_BUDGET := 0.1

## Ordered: only the first not-yet-owned item is purchasable. `id` must stay
## stable across saves once players own it.
const ITEMS: Array[Dictionary] = [
	{"id": "plant", "name_key": "SHOP_ITEM_PLANT", "cost": 300},
	{"id": "lamp", "name_key": "SHOP_ITEM_LAMP", "cost": 600},
]

var budget := 0
var owned: Array[String] = []
var persist := true  # the autoplay bot turns this off, same pattern as GameManager.persist_highscore

## Overridable so tests can round-trip through a scratch file instead of the real one.
var save_path := SAVE_PATH


func _ready() -> void:
	_load()
	GameManager.game_over.connect(func(_reason: String) -> void: _credit_run())


func _credit_run() -> void:
	var earned := int(GameManager.score * SCORE_TO_BUDGET)
	if earned <= 0:
		return
	budget += earned
	if persist:
		_save()
	budget_changed.emit(budget)


func is_owned(item_id: String) -> bool:
	return item_id in owned


## The next purchasable item, or {} once everything is owned.
func next_item() -> Dictionary:
	for item in ITEMS:
		if not is_owned(item.id):
			return item
	return {}


func can_afford_next() -> bool:
	var item := next_item()
	return not item.is_empty() and budget >= item.cost


## Spends budget for another system (e.g. EraManager's era unlocks). Returns whether
## the spend happened.
func spend(amount: int) -> bool:
	if budget < amount:
		return false
	budget -= amount
	if persist:
		_save()
	budget_changed.emit(budget)
	return true


## Buys the next item if affordable. Returns whether a purchase happened.
func buy_next() -> bool:
	var item := next_item()
	if item.is_empty() or budget < item.cost:
		return false
	budget -= item.cost
	owned.append(item.id)
	if persist:
		_save()
	budget_changed.emit(budget)
	item_purchased.emit(item.id)
	return true


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		return
	budget = cfg.get_value("progress", "budget", 0)
	owned.clear()
	for id in cfg.get_value("progress", "owned", []):
		owned.append(id)


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "budget", budget)
	cfg.set_value("progress", "owned", owned)
	cfg.save(save_path)
