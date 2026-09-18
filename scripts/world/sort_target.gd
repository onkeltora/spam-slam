class_name SortTarget
extends Node2D
## One sorting target for a swipe direction, medium-agnostic: slot position/movement,
## drag-preview/hit/miss animation state. How it looks is up to a subclass's _draw()
## -- SortFolder for a 90er desktop folder icon, PaperTray for a 60er physical tray.
## Origin = target center.

var category: MailData.Category
var dir: GameManager.Dir

var _preview := 0.0        # 0..1 while the player drags towards this target
var _gulp := 0.0           # opens after a correct hit
var _shake := 0.0          # wiggle after a wrong hit
var _correct_flash := 0.0  # blinking focus frame: "this would have been right"
var _time := 0.0


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func setup(p_category: MailData.Category, p_dir: GameManager.Dir) -> void:
	category = p_category
	dir = p_dir
	position = ScreenLayout.folder_slots()[dir]
	GameManager.language_changed.connect(queue_redraw)
	queue_redraw()


func move_to_slot(new_dir: GameManager.Dir) -> void:
	if new_dir == dir:
		return
	dir = new_dir
	create_tween().tween_property(self, "position", ScreenLayout.folder_slots()[dir], 0.55) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	_correct_flash = 1.6


func set_preview(amount: float) -> void:
	_preview = amount


func gulp() -> void:
	_gulp = 1.0


func reject() -> void:
	_shake = 1.0


func flash_correct() -> void:
	_correct_flash = 1.1


func _process(delta: float) -> void:
	_time += delta
	_gulp = move_toward(_gulp, 0.0, delta * 3.0)
	_shake = move_toward(_shake, 0.0, delta * 2.5)
	_correct_flash = move_toward(_correct_flash, 0.0, delta)
	scale = Vector2.ONE * (1.0 + sin(_gulp * PI) * 0.18 + _preview * 0.1)
	queue_redraw()
