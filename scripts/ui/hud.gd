extends CanvasLayer
## HUD root. Most widgets listen to GameManager themselves; this script only
## handles the full-screen damage/boost flash.

@onready var flash_rect: ColorRect = %FlashRect


func _ready() -> void:
	GameManager.boost_started.connect(func(_d: float) -> void: flash(Color(1.0, 0.7, 0.3), 0.3))
	GameManager.mail_sorted.connect(func(result: Dictionary) -> void:
		if not result.correct:
			flash(Color(1, 0.1, 0.05), 0.35))


func flash(color: Color, strength: float) -> void:
	flash_rect.color = Color(color, strength)
	create_tween().tween_property(flash_rect, "color:a", 0.0, 0.35)
