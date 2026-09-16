class_name FloatingText
extends Node2D
## Comic-style popup text that pops, rises and fades.

var text := ""
var color := Color.WHITE
var font_size := 30
var rise := 70.0
var duration := 0.9


static func spawn(parent: Node, pos: Vector2, p_text: String, p_color: Color, p_size: int = 30,
		p_duration: float = 0.9, p_rise: float = 70.0) -> FloatingText:
	var ft := FloatingText.new()
	ft.rise = p_rise
	ft.text = p_text
	ft.color = p_color
	ft.font_size = p_size
	ft.duration = p_duration
	ft.position = pos
	ft.z_index = 20
	parent.add_child(ft)
	return ft


func _ready() -> void:
	scale = Vector2.ONE * 1.6
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y - rise, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, duration * 0.35).set_delay(duration * 0.65)
	tween.chain().tween_callback(queue_free)


func _draw() -> void:
	DrawUtil.text_centered(self, text, Vector2.ZERO, font_size, color, 8, Color(0.08, 0.05, 0.05))
