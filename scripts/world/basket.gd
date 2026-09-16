class_name Basket
extends Node2D
## One of the four sorting trays at the screen edges. Origin = tray center.
## Shows its category + base-rule legend, reacts to drag preview, hits and misses.

const SLOTS := {
	GameManager.Dir.UP: {"pos": Vector2(640, 54), "size": Vector2(320, 88)},
	GameManager.Dir.DOWN: {"pos": Vector2(640, 666), "size": Vector2(320, 88)},
	GameManager.Dir.LEFT: {"pos": Vector2(108, 395), "size": Vector2(176, 250)},
	GameManager.Dir.RIGHT: {"pos": Vector2(1172, 395), "size": Vector2(176, 250)},
}
const ARROWS := {
	GameManager.Dir.UP: "▲",
	GameManager.Dir.DOWN: "▼",
	GameManager.Dir.LEFT: "◀",
	GameManager.Dir.RIGHT: "▶",
}

var category: MailData.Category
var dir: GameManager.Dir
var tray_size := Vector2(320, 88)

var _preview := 0.0        # 0..1 while the player drags towards this basket
var _gulp := 0.0           # bounce after a correct hit
var _shake := 0.0          # wiggle after a wrong hit
var _correct_flash := 0.0  # blinking outline: "this would have been right"
var _time := 0.0


func setup(p_category: MailData.Category, p_dir: GameManager.Dir) -> void:
	category = p_category
	dir = p_dir
	position = SLOTS[dir].pos
	tray_size = SLOTS[dir].size
	GameManager.language_changed.connect(queue_redraw)
	queue_redraw()


func move_to_slot(new_dir: GameManager.Dir) -> void:
	if new_dir == dir:
		return
	dir = new_dir
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position", SLOTS[dir].pos, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "tray_size", SLOTS[dir].size, 0.55).set_trans(Tween.TRANS_CUBIC)
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
	_gulp = move_toward(_gulp, 0.0, delta * 4.0)
	_shake = move_toward(_shake, 0.0, delta * 2.5)
	_correct_flash = move_toward(_correct_flash, 0.0, delta)
	var bounce := sin(_gulp * PI) * 0.12
	scale = Vector2.ONE * (1.0 + bounce + _preview * 0.06)
	queue_redraw()


func _draw() -> void:
	var color: Color = MailData.CATEGORY_COLORS[category]
	var offset := Vector2(sin(_time * 60.0) * 9.0 * _shake, 0.0)
	var rect := Rect2(-tray_size * 0.5 + offset, tray_size)

	# Tray: dark inner well + colored rim, brighter while previewed
	var glow := _preview * 0.5 + _gulp * 0.6
	DrawUtil.rounded_rect(self, Rect2(rect.position + Vector2(5, 7), rect.size), 12, Color(0, 0, 0, 0.35))
	DrawUtil.rounded_rect(self, rect, 12, color.darkened(0.55).lerp(color, glow * 0.6))
	DrawUtil.rounded_rect(self, rect.grow(-9), 8, Color(0.08, 0.07, 0.06, 0.55 - glow * 0.3))
	DrawUtil.rounded_frame(self, rect, 12, color.lightened(glow * 0.5), 4)
	if _shake > 0.0:
		DrawUtil.rounded_frame(self, rect.grow(4), 14, Color(1, 0.15, 0.1, _shake), 5)
	if _correct_flash > 0.0 and fmod(_time * 8.0, 2.0) < 1.3:
		DrawUtil.rounded_frame(self, rect.grow(7), 16, Color(1, 1, 1, minf(_correct_flash, 1.0)), 5)

	var name_text := tr(MailData.CATEGORY_KEYS[category])
	var legend := tr(MailData.BASE_RULE_KEYS[category])
	var arrow: String = ARROWS[dir]
	var c := rect.get_center()
	var max_w := rect.size.x - 20
	var name_size := DrawUtil.fit_size(name_text, 30, max_w)
	var legend_size := DrawUtil.fit_size(legend, 17, max_w)

	if tray_size.x > tray_size.y:
		DrawUtil.text_centered(self, arrow + " " + name_text + " " + arrow, c + Vector2(0, -13),
				DrawUtil.fit_size(arrow + " " + name_text + " " + arrow, 30, max_w), color.lightened(0.35), 5)
		DrawUtil.text_centered(self, legend, c + Vector2(0, 22), legend_size, Color(1, 1, 1, 0.85), 3)
	else:
		DrawUtil.text_centered(self, arrow, c + Vector2(0, -70), 30, color.lightened(0.35), 5)
		DrawUtil.text_centered(self, name_text, c + Vector2(0, -10), name_size, color.lightened(0.35), 5)
		DrawUtil.text_centered(self, legend, c + Vector2(0, 40), legend_size, Color(1, 1, 1, 0.85), 3)
